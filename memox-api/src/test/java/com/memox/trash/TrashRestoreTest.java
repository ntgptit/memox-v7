package com.memox.trash;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.common.error.ApiErrorCode;
import com.memox.common.scheduler.SchedulerType;
import com.memox.card.exception.CardConflictException;
import com.memox.deck.enums.DeckContentType;
import com.memox.deck.exception.DeckConflictException;
import com.memox.support.PostgresIntegrationTest;
import com.memox.trash.entity.TrashBatchRow;
import com.memox.trash.exception.TrashConflictException;
import com.memox.trash.exception.TrashNotFoundException;
import com.memox.trash.service.DeleteCardsCommand;
import com.memox.trash.service.DeleteDeckCommand;
import com.memox.trash.service.RestoreBatchCommand;
import com.memox.trash.service.TrashDeleteService;
import com.memox.trash.service.TrashRestoreService;

class TrashRestoreTest extends PostgresIntegrationTest {

	@Autowired
	private TrashDeleteService trashDeleteService;

	@Autowired
	private TrashRestoreService trashRestoreService;

	/** BR-262: exactly the rows carrying the batch, and no row of any other batch. */
	@Test
	void revivesOnlyTheRowsOfTheChosenBatch() {
		seedCardDeck();
		insertCardWithState("c1", "deck", null, null);
		insertCardWithState("c2", "deck", null, null);
		final var first = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c1")));
		trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c2")));

		trashRestoreService.restore(new RestoreBatchCommand(first.get(0).id(), "deck"));

		assertThat(batchIdOfCard("c1")).isNull();
		assertThat(batchIdOfCard("c2")).isNotNull();
	}

	/**
	 * A restored sub-deck lands at the end of its sibling group, even restored in place.
	 *
	 * <p>The plan justified this by saying the old position may have been taken by a sibling created
	 * after the delete. It cannot have been: a tombstone keeps its {@code sibling_position}, and
	 * {@code nextSiblingPosition} is {@code MAX(sibling_position) + 1} over every row in the scope,
	 * tombstones included. The real reason is BR-261 — a restore <em>is</em> a move, held to the
	 * move's rules with no second rule set of its own, and a move always takes a fresh slot.
	 */
	@Test
	void givesARestoredDeckAFreshPositionAtTheEndOfItsGroup() {
		insertRootDeck("root", "Korean");
		insertSubDeckAt("a", "A", "root", "root", 0);
		final var batch = trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));
		insertSubDeckAt("b", "B", "root", "root", 1);

		trashRestoreService.restore(new RestoreBatchCommand(batch.id(), "root"));

		assertThat(siblingPositionOf("a")).isEqualTo(2);
		assertThat(siblingPositionOf("b")).isEqualTo(1);
	}

	/**
	 * Restoring into a <em>different</em> parent is the real collision, and it takes a fresh slot.
	 *
	 * <p>The tombstone keeps the position it held in its old scope, which says nothing about the new
	 * one. The move does exactly this — {@code nextSiblingPosition(target)} — and restore reuses it
	 * rather than inventing a second rule (BR-261).
	 */
	@Test
	void takesAFreshPositionWhenRestoringIntoADifferentParent() {
		insertRootDeck("root", "Korean");
		insertSubDeckAt("home", "Home", "root", "root", 0);
		insertSubDeckAt("elsewhere", "Elsewhere", "root", "root", 1);
		insertSubDeckAt("moved", "Moved", "home", "root", 0);
		insertSubDeckAt("resident", "Resident", "elsewhere", "root", 0);
		final var batch = trashDeleteService.deleteDeck(new DeleteDeckCommand("moved"));

		trashRestoreService.restore(new RestoreBatchCommand(batch.id(), "elsewhere"));

		assertThat(siblingPositionOf("moved")).isEqualTo(1);
		assertThat(siblingPositionOf("resident")).isZero();
	}

	/**
	 * BR-262: a restored deck rewrites {@code root_deck_id} across its whole subtree, tombstones
	 * inside it included.
	 *
	 * <p>A branch deleted earlier still lives under this deck. Left pointing at the old root, it
	 * would hand back a deck naming a tree it does not belong to the day it is restored itself.
	 */
	@Test
	void rewritesTheRootAcrossTheWholeSubtreeIncludingItsOwnTombstones() {
		insertRootDeck("home", "Korean");
		insertRootDeck("away", "Korean II");
		insertSubDeck("moved", "Unit 1", "home", "home", DeckContentType.DECK);
		insertSubDeck("buried", "Lesson 1", "moved", "home", DeckContentType.UNSET);
		trashDeleteService.deleteDeck(new DeleteDeckCommand("buried"));
		final var batch = trashDeleteService.deleteDeck(new DeleteDeckCommand("moved"));

		trashRestoreService.restore(new RestoreBatchCommand(batch.id(), "away"));

		assertThat(rootDeckIdOf("moved")).isEqualTo("away");
		assertThat(rootDeckIdOf("buried")).isEqualTo("away");
		assertThat(batchIdOfDeck("buried")).isNotNull();
	}

	/**
	 * BR-261 borrows BR-55 whole: depth of the target plus the batch's own height.
	 *
	 * <p>The chain is already ten deep, so nothing at all fits under {@code d10} — and the deck
	 * being restored comes from a second tree on the same scheduler, so this test breaks the depth
	 * rule and only the depth rule.
	 */
	@Test
	void refusesARestoreThatWouldExceedTenLevels() {
		insertChain(10);
		insertRootDeck("other", "Korean");
		insertSubDeck("spare", "Spare", "other", "other", DeckContentType.UNSET);
		final var batch = trashDeleteService.deleteDeck(new DeleteDeckCommand("spare"));

		assertThatThrownBy(() -> trashRestoreService.restore(new RestoreBatchCommand(batch.id(), "d10")))
				.isInstanceOf(DeckConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.DECK_DEPTH_EXCEEDED);
	}

	/** BR-261 borrows BR-64 whole: a deck holding cards cannot take a sub-deck. */
	@Test
	void refusesATargetThatHoldsCards() {
		insertRootDeck("root", "Korean");
		insertSubDeck("holder", "Holder", "root", "root", DeckContentType.CARD);
		insertSubDeck("moved", "Moved", "root", "root", DeckContentType.UNSET);
		final var batch = trashDeleteService.deleteDeck(new DeleteDeckCommand("moved"));

		assertThatThrownBy(() ->
				trashRestoreService.restore(new RestoreBatchCommand(batch.id(), "holder")))
				.isInstanceOf(DeckConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.PARENT_HOLDS_CARDS);
	}

	/** BR-261 borrows BR-70/74 whole: two roots on different schedulers do not exchange subtrees. */
	@Test
	void refusesATargetInARootWithADifferentScheduler() {
		insertRootDeck("home", "Korean", SchedulerType.EIGHT_BOX);
		insertRootDeck("away", "Korean II", SchedulerType.SM2);
		insertSubDeck("moved", "Unit 1", "home", "home", DeckContentType.UNSET);
		final var batch = trashDeleteService.deleteDeck(new DeleteDeckCommand("moved"));

		assertThatThrownBy(() -> trashRestoreService.restore(new RestoreBatchCommand(batch.id(), "away")))
				.isInstanceOf(DeckConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.DECK_CROSS_ROOT_MOVE);
	}

	/**
	 * BR-261: a root deck has exactly one valid target, the top level, and no other item may use it.
	 *
	 * <p>A root has no parent (BR-56) and move does not apply to it, so there is nothing to
	 * re-parent — clearing the tombstones is the whole operation. Writing {@code parent_deck_id} or
	 * {@code root_deck_id} again would give a fact that never changed a second owner.
	 */
	@Test
	void restoresARootDeckToTheTopLevelAndNowhereElse() {
		insertRootDeck("root", "Korean");
		insertRootDeck("other", "Korean II");
		final var batch = trashDeleteService.deleteDeck(new DeleteDeckCommand("root"));

		assertThatThrownBy(() -> trashRestoreService.restore(new RestoreBatchCommand(batch.id(), "other")))
				.isInstanceOf(TrashConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.RESTORE_TARGET_INVALID);

		trashRestoreService.restore(new RestoreBatchCommand(batch.id(), null));

		assertThat(batchIdOfDeck("root")).isNull();
		assertThat(rootDeckIdOf("root")).isEqualTo("root");
	}

	@Test
	void refusesASubDeckAndACardAtTheTopLevel() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState("c1", "deck", null, null);
		final var cardBatch = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c1")));
		final var deckBatch = trashDeleteService.deleteDeck(new DeleteDeckCommand("deck"));

		assertThatThrownBy(() ->
				trashRestoreService.restore(new RestoreBatchCommand(cardBatch.get(0).id(), null)))
				.isInstanceOf(TrashConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.RESTORE_TARGET_INVALID);
		assertThatThrownBy(() ->
				trashRestoreService.restore(new RestoreBatchCommand(deckBatch.id(), null)))
				.isInstanceOf(TrashConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.RESTORE_TARGET_INVALID);
	}

	/** BR-165 for a restored card: same root, non-root target, holding cards or nothing yet. */
	@Test
	void refusesACardIntoADeckOfAnotherRoot() {
		insertRootDeck("home", "Korean");
		insertRootDeck("away", "Korean II");
		insertSubDeck("here", "Unit 1", "home", "home", DeckContentType.CARD);
		insertSubDeck("there", "Unit 1", "away", "away", DeckContentType.UNSET);
		insertCardWithState("c1", "here", null, null);
		final var batch = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c1")));

		assertThatThrownBy(() ->
				trashRestoreService.restore(new RestoreBatchCommand(batch.get(0).id(), "there")))
				.isInstanceOf(CardConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.CARD_CROSS_ROOT_MOVE);
	}

	/** BR-62, BR-163: the target learns what it holds in the same transaction. */
	@Test
	void setsAnUnsetTargetToTheKindItJustGained() {
		insertRootDeck("root", "Korean");
		insertSubDeck("source", "Unit 1", "root", "root", DeckContentType.CARD);
		insertSubDeck("target", "Unit 2", "root", "root", DeckContentType.UNSET);
		insertCardWithState("c1", "source", null, null);
		final var batch = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c1")));

		trashRestoreService.restore(new RestoreBatchCommand(batch.get(0).id(), "target"));

		assertThat(contentTypeOf("target")).isEqualTo(DeckContentType.CARD);
	}

	/** Once every row is active again the batch owns nothing, so it must not stay in the list. */
	@Test
	void removesTheBatchOnceItsRowsAreBack() {
		seedCardDeck();
		insertCardWithState("c1", "deck", null, null);
		final var batch = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c1")));

		trashRestoreService.restore(new RestoreBatchCommand(batch.get(0).id(), "deck"));

		assertThat(trashRestoreService.list()).isEmpty();
		assertThat(cardExists("c1")).isTrue();
	}

	@Test
	void refusesABatchThatIsNotThere() {
		assertThatThrownBy(() -> trashRestoreService.restore(new RestoreBatchCommand("ghost", "deck")))
				.isInstanceOf(TrashNotFoundException.class);
	}

	/** Translation row 2: an empty aggregate is {@code '[]'}, never null. */
	@Test
	void reportsAnEmptyOriginPathForATopLevelItem() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.UNSET);
		trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));

		assertThat(trashRestoreService.list()).singleElement()
				.extracting(TrashBatchRow::originPath).isEqualTo(List.of());
	}

	/**
	 * The list counts the batch, not the subtree — what a restore would bring back (BR-262).
	 *
	 * <p>A descendant already in Trash under an older batch carries that older id, so it is absent
	 * from both counts. That is exactly the number the confirmation has to show.
	 */
	@Test
	void countsWhatTheBatchWouldBringBackRatherThanTheWholeSubtree() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.CARD);
		insertCardWithState("kept", "b", null, null);
		insertCardWithState("older", "b", null, null);
		trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("older")));

		trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));

		assertThat(trashRestoreService.list()).first().satisfies(row -> {
			assertThat(row.itemName()).isEqualTo("Unit 1");
			assertThat(row.originDeckId()).isEqualTo("root");
			assertThat(row.originDeckName()).isEqualTo("Korean");
			assertThat(row.batchDeckCount()).isEqualTo(2L);
			assertThat(row.batchCardCount()).isEqualTo(1L);
		});
	}

	/** The origin walk crosses tombstones on purpose: where it was is still the honest answer. */
	@Test
	void readsAnOriginPathThatRunsThroughATrashedAncestor() {
		insertRootDeck("root", "Korean");
		insertSubDeck("mid", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("leaf", "Lesson 1", "mid", "root", DeckContentType.CARD);
		insertCardWithState("c1", "leaf", null, null);
		trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c1")));
		trashDeleteService.deleteDeck(new DeleteDeckCommand("mid"));

		assertThat(trashRestoreService.list())
				.filteredOn(row -> "c1".equals(row.rootItemId()))
				.singleElement()
				.satisfies(row -> assertThat(row.originPath())
						.extracting("id").containsExactly("mid", "root"));
	}

	private void seedCardDeck() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
	}
}
