package com.memox.trash;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.deck.enums.DeckContentType;
import com.memox.support.PostgresIntegrationTest;
import com.memox.trash.service.DeleteCardsCommand;
import com.memox.trash.service.DeleteDeckCommand;
import com.memox.trash.service.TrashDeleteService;
import com.memox.trash.service.TrashPurgeService;

class TrashPurgeTest extends PostgresIntegrationTest {

	private static final Duration RETENTION = Duration.ofDays(30);

	@Autowired
	private TrashPurgeService trashPurgeService;

	@Autowired
	private TrashDeleteService trashDeleteService;

	/** BR-264: {@code now - deleted_at >= 30 days}, and the exact boundary is eligible. */
	@Test
	void purgesABatchExactlyAtTheThirtyDayBoundary() {
		seedCardDeck();
		insertCardWithState("c1", "deck", null, null);
		final var batch = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c1")));
		backdateBatch(batch.get(0).id(), RETENTION);

		assertThat(trashPurgeService.purgeExpired().purgedBatches()).isEqualTo(1);
		assertThat(cardExists("c1")).isFalse();
	}

	/** BR-264: a day short of the window is not eligible, however close it is. */
	@Test
	void leavesABatchOneDayShortOfTheWindowAlone() {
		seedCardDeck();
		insertCardWithState("c1", "deck", null, null);
		final var batch = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c1")));
		backdateBatch(batch.get(0).id(), Duration.ofDays(29));

		assertThat(trashPurgeService.purgeExpired().purgedBatches()).isZero();
		assertThat(cardExists("c1")).isTrue();
	}

	/**
	 * BR-265: the cascade is the purge, so everything hanging off the card goes with it.
	 *
	 * <p>{@code purgeBatch} deletes one row. Both tombstone columns reference {@code delete_batches}
	 * {@code ON DELETE CASCADE}, and the card's own foreign keys carry the study state, the answers
	 * and the tag links away behind it. Asserted rather than assumed: nothing in the Java says so.
	 */
	@Test
	void cascadesFromTheBatchRowToTheStudyStateAndTheTagLinks() {
		seedCardDeck();
		insertCardWithState("c1", "deck", null, null);
		insertTag("t-a", "alpha");
		linkTag("c1", "t-a");
		final var batch = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c1")));
		backdateBatch(batch.get(0).id(), RETENTION);

		trashPurgeService.purgeExpired();

		assertThat(countOf("SELECT COUNT(*) FROM card_study_states WHERE card_id = 'c1'")).isZero();
		assertThat(countOf("SELECT COUNT(*) FROM card_tags WHERE card_id = 'c1'")).isZero();
		assertThat(tagExists("t-a")).isTrue();
	}

	/**
	 * BR-265: a cascade that would reach a row outside the batch skips the batch whole.
	 *
	 * <p>Skipped rather than refused: nobody asked for this sweep, so one blocked batch must not take
	 * the rest of it down. A user-requested purge is the opposite case — they named the batches, so
	 * a blocker is an answer they have to see.
	 */
	@Test
	void skipsABatchWhoseSubtreeStillHoldsAnActiveRow() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.CARD);
		final var batch = trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));
		reviveDeckWithoutBatch("b");
		backdateBatch(batch.id(), Duration.ofDays(31));

		final var report = trashPurgeService.purgeExpired();

		assertThat(report.purgedBatches()).isZero();
		assertThat(report.skippedBatches()).isEqualTo(1);
		assertThat(deckExists("a")).isTrue();
	}

	/**
	 * BR-265: a descendant in a batch that is <em>not yet</em> eligible blocks its ancestor too.
	 *
	 * <p>The blocker probe measures against the batches this sweep is allowed to remove, not against
	 * "is it deleted" — otherwise the ancestor's cascade would take a tombstone whose own thirty days
	 * have not run out.
	 */
	@Test
	void skipsAnAncestorWhoseDescendantBatchIsNotYetEligible() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.CARD);
		insertCardWithState("young", "b", null, null);
		trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("young")));
		final var older = trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));
		backdateBatch(older.id(), Duration.ofDays(31));

		final var report = trashPurgeService.purgeExpired();

		assertThat(report.purgedBatches()).isZero();
		assertThat(report.skippedBatches()).isEqualTo(1);
		assertThat(deckExists("a")).isTrue();
		assertThat(cardExists("young")).isTrue();
	}

	/** Both eligible: the descendant's batch goes, and its ancestor's is then free to go too. */
	@Test
	void purgesAnAncestorOnceItsDescendantBatchIsEligibleAsWell() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.CARD);
		insertCardWithState("early", "b", null, null);
		final var first = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("early")));
		final var second = trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));
		backdateBatch(first.get(0).id(), Duration.ofDays(40));
		backdateBatch(second.id(), Duration.ofDays(31));

		assertThat(trashPurgeService.purgeExpired().purgedBatches()).isEqualTo(2);
		assertThat(deckExists("a")).isFalse();
		assertThat(cardExists("early")).isFalse();
	}

	/** BR-264: the sweep runs on every trigger, so running it twice must be free and harmless. */
	@Test
	void isIdempotentWhenNothingIsEligible() {
		assertThat(trashPurgeService.purgeExpired().purgedBatches()).isZero();
		assertThat(trashPurgeService.purgeExpired().purgedBatches()).isZero();
	}

	private long countOf(final String sql) {
		return this.jdbcTemplate.queryForObject(sql, Long.class);
	}

	private void seedCardDeck() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
	}
}
