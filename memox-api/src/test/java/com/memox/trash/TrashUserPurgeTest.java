package com.memox.trash;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Duration;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.common.error.ApiErrorCode;
import com.memox.deck.enums.DeckContentType;
import com.memox.support.PostgresIntegrationTest;
import com.memox.trash.exception.TrashConflictException;
import com.memox.trash.exception.TrashNotFoundException;
import com.memox.trash.service.DeleteCardsCommand;
import com.memox.trash.service.DeleteDeckCommand;
import com.memox.trash.service.TrashDeleteService;
import com.memox.trash.service.TrashPurgeService;

/**
 * BR-266: the purge a user asked for, which is not the retention sweep with a different trigger.
 *
 * <p>The same blocker signal means opposite things to the two callers. The sweep <em>skips</em> a
 * blocked batch, because nobody asked for this and one blocked batch must not take the rest of the
 * sweep down. This one <em>refuses</em>, because the user named these batches and a blocker is an
 * answer they have to see.
 */
class TrashUserPurgeTest extends PostgresIntegrationTest {

	@Autowired
	private TrashPurgeService trashPurgeService;

	@Autowired
	private TrashDeleteService trashDeleteService;

	/** No retention wait: the user asked, so the thirty days do not apply. */
	@Test
	void purgesTheNamedBatchesImmediately() {
		seedCardDeck();
		insertCardWithState("c1", "deck", null, null);
		insertCardWithState("c2", "deck", null, null);
		final var batches = trashDeleteService.deleteCards(
				new DeleteCardsCommand(List.of("c1", "c2")));

		final var report = trashPurgeService.purge(
				batches.stream().map(batch -> batch.id()).toList());

		assertThat(report.purgedBatches()).isEqualTo(2);
		assertThat(cardExists("c1")).isFalse();
		assertThat(cardExists("c2")).isFalse();
	}

	/**
	 * UC-21 E6: a batch another run already took makes the whole request a not-found.
	 *
	 * <p>Checked first and on its own, never folded into the blocker probe — purging "the rest"
	 * would act on a set the user never saw, after a confirmation that named an exact count.
	 */
	@Test
	void refusesTheWholeRequestWhenANamedBatchIsAlreadyGone() {
		seedCardDeck();
		insertCardWithState("c1", "deck", null, null);
		final var batch = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c1")));

		assertThatThrownBy(() -> trashPurgeService.purge(List.of(batch.get(0).id(), "ghost")))
				.isInstanceOf(TrashNotFoundException.class);

		assertThat(trashRestoreBatchExists(batch.get(0).id())).isTrue();
		assertThat(cardExists("c1")).isTrue();
	}

	/**
	 * BR-265: a cascade that would reach a row outside the named set refuses, and refuses whole.
	 *
	 * <p>The allowed set is exactly what the user named — not "everything past retention". A purge
	 * that quietly rode along with unrelated eligible batches would remove rows nobody confirmed.
	 */
	@Test
	void refusesWhenTheCascadeWouldReachABatchTheUserDidNotName() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.CARD);
		insertCardWithState("inner", "b", null, null);
		trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("inner")));
		final var outer = trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));

		assertThatThrownBy(() -> trashPurgeService.purge(List.of(outer.id())))
				.isInstanceOf(TrashConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.PURGE_BLOCKED);

		assertThat(deckExists("a")).isTrue();
		assertThat(cardExists("inner")).isTrue();
	}

	/**
	 * Naming both batches un-blocks the cascade — as long as they are the same kind of thing.
	 *
	 * <p>Two nested deck batches: the inner one was deleted first and kept its own tombstone
	 * (BR-258), so purging the outer one alone would cascade into rows the user did not name. Named
	 * together, the cascade stays inside what was confirmed.
	 */
	@Test
	void purgesNestedDeckBatchesWhenBothAreNamed() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.UNSET);
		final var inner = trashDeleteService.deleteDeck(new DeleteDeckCommand("b"));
		final var outer = trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));

		assertThatThrownBy(() -> trashPurgeService.purge(List.of(outer.id())))
				.isInstanceOf(TrashConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.PURGE_BLOCKED);

		assertThat(trashPurgeService.purge(List.of(inner.id(), outer.id())).purgedBatches())
				.isEqualTo(2);
		assertThat(deckExists("a")).isFalse();
		assertThat(deckExists("b")).isFalse();
	}

	/**
	 * The consequence of BR-266 that is worth writing down: some batches cannot be hand-purged.
	 *
	 * <p>A deck batch whose subtree still holds an older <em>card</em> batch is blocked, and the one
	 * selection that would un-block it — naming both — mixes item types, which BR-266 forbids. So it
	 * waits for retention, and the sweep takes both once each has served its thirty days. That is
	 * not a gap in this endpoint: the Flutter client reaches the same dead end, because its
	 * selection state will not let those two rows be picked together either.
	 */
	@Test
	void leavesADeckBatchOverAnOlderCardBatchToRetention() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.CARD);
		insertCardWithState("inner", "b", null, null);
		final var cardBatch = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("inner")));
		final var deckBatch = trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));

		assertThatThrownBy(() -> trashPurgeService.purge(List.of(deckBatch.id())))
				.isInstanceOf(TrashConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.PURGE_BLOCKED);
		assertThatThrownBy(() -> trashPurgeService.purge(List.of(cardBatch.get(0).id(), deckBatch.id())))
				.isInstanceOf(TrashConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.PURGE_MIXES_ITEM_TYPES);

		// Retention is the way out, and it takes both.
		backdateBatch(cardBatch.get(0).id(), Duration.ofDays(31));
		backdateBatch(deckBatch.id(), Duration.ofDays(31));
		assertThat(trashPurgeService.purgeExpired().purgedBatches()).isEqualTo(2);
		assertThat(deckExists("a")).isFalse();
	}

	/**
	 * BR-266: a selection must not mix card and deck.
	 *
	 * <p>The Flutter app enforces this in the selection state, where a non-matching row simply
	 * cannot be picked. An HTTP client has no selection state, so the rule is unenforced at this
	 * boundary unless the endpoint enforces it — and the confirmation the rule is really about names
	 * one kind of thing and a count of it.
	 */
	@Test
	void refusesASelectionThatMixesCardsAndDecks() {
		seedCardDeck();
		insertCardWithState("c1", "deck", null, null);
		insertSubDeck("spare", "Unit 2", "root", "root", DeckContentType.UNSET);
		final var cardBatch = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c1")));
		final var deckBatch = trashDeleteService.deleteDeck(new DeleteDeckCommand("spare"));

		assertThatThrownBy(() ->
				trashPurgeService.purge(List.of(cardBatch.get(0).id(), deckBatch.id())))
				.isInstanceOf(TrashConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.PURGE_MIXES_ITEM_TYPES);

		assertThat(cardExists("c1")).isTrue();
		assertThat(deckExists("spare")).isTrue();
	}

	/** The sweep still skips what this refuses — same probe, opposite policies. */
	@Test
	void theSweepStillSkipsWhatTheUserPurgeRefuses() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.CARD);
		insertCardWithState("inner", "b", null, null);
		trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("inner")));
		final var outer = trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));
		backdateBatch(outer.id(), Duration.ofDays(31));

		final var report = trashPurgeService.purgeExpired();

		assertThat(report.purgedBatches()).isZero();
		assertThat(report.skippedBatches()).isEqualTo(1);
	}

	/**
	 * A repeated id is one batch, not two.
	 *
	 * <p>The response carries a count, and a confirmation named one before the call. Counting a
	 * duplicate twice would report a number nobody agreed to — the same normalisation BR-174 asks of
	 * an export selection.
	 */
	@Test
	void countsARepeatedIdOnce() {
		seedCardDeck();
		insertCardWithState("c1", "deck", null, null);
		final var batch = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c1")));

		final var report = trashPurgeService.purge(
				List.of(batch.get(0).id(), batch.get(0).id()));

		assertThat(report.purgedBatches()).isEqualTo(1);
		assertThat(cardExists("c1")).isFalse();
	}

	@Test
	void refusesAnEmptySelection() {
		assertThatThrownBy(() -> trashPurgeService.purge(List.of()))
				.isInstanceOf(com.memox.common.error.ValidationFailedException.class);
	}

	private boolean trashRestoreBatchExists(final String batchId) {
		return this.jdbcTemplate.queryForObject(
				"SELECT EXISTS (SELECT 1 FROM delete_batches WHERE id = ?)", Boolean.class, batchId);
	}

	private void seedCardDeck() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
	}
}
