package com.memox.trash;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.card.exception.CardNotFoundException;
import com.memox.deck.enums.DeckContentType;
import com.memox.deck.exception.DeckNotFoundException;
import com.memox.support.PostgresIntegrationTest;
import com.memox.trash.entity.DeleteBatch;
import com.memox.trash.enums.TrashItemType;
import com.memox.trash.service.DeleteCardsCommand;
import com.memox.trash.service.DeleteDeckCommand;
import com.memox.trash.service.TrashDeleteService;

class TrashDeleteTest extends PostgresIntegrationTest {

	@Autowired
	private TrashDeleteService trashDeleteService;

	/** BR-258: one batch, one instant, every active descendant — deck and card alike. */
	@Test
	void stampsTheWholeActiveSubtreeWithOneBatchAndOneInstant() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.CARD);
		insertCardWithState("c1", "b", null, null);

		final var batch = trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));

		assertThat(batch.itemType()).isEqualTo(TrashItemType.DECK);
		assertThat(batch.rootItemId()).isEqualTo("a");
		assertThat(batchIdOfDeck("a")).isEqualTo(batch.id());
		assertThat(batchIdOfDeck("b")).isEqualTo(batch.id());
		assertThat(batchIdOfCard("c1")).isEqualTo(batch.id());
	}

	/** BR-258: a descendant already in Trash keeps its old tombstone and is not absorbed. */
	@Test
	void leavesAnEarlierTombstoneInItsOriginalBatch() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.CARD);
		insertCardWithState("old", "b", null, null);
		final var first = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("old")));

		final var second = trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));

		assertThat(batchIdOfCard("old")).isEqualTo(first.get(0).id());
		assertThat(batchIdOfDeck("a")).isEqualTo(second.id());
	}

	/**
	 * BR-256: one batch per item root, never one shared batch for the action.
	 *
	 * <p>The item root is singular, and someone who deletes fifty cards may want three of them
	 * back. A shared batch could only give them that through a partial restore, which BR-262 does
	 * not have — it restores exactly the rows carrying the batch.
	 */
	@Test
	void createsOneBatchPerCardRatherThanOnePerAction() {
		seedCardDeck();
		insertCardWithState("c1", "deck", null, null);
		insertCardWithState("c2", "deck", null, null);

		final var batches = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c1", "c2")));

		assertThat(batches).hasSize(2)
				.extracting(DeleteBatch::rootItemId).containsExactly("c1", "c2");
		assertThat(batches).extracting(DeleteBatch::id).doesNotHaveDuplicates();
		assertThat(batchIdOfCard("c1")).isEqualTo(batches.get(0).id());
		assertThat(batchIdOfCard("c2")).isEqualTo(batches.get(1).id());
	}

	/** One action is one instant, however many batches it opens (BR-256). */
	@Test
	void sharesOneDeletedAtAcrossEveryBatchOfOneAction() {
		seedCardDeck();
		insertCardWithState("c1", "deck", null, null);
		insertCardWithState("c2", "deck", null, null);

		final var batches = trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("c1", "c2")));

		assertThat(batches).extracting(DeleteBatch::deletedAt).containsOnly(batches.get(0).deletedAt());
	}

	/** BR-260: the deck that just lost its last active card drops to unset, in the same transaction. */
	@Test
	void returnsTheEmptiedParentToUnset() {
		seedCardDeck();
		insertCardWithState("only", "deck", null, null);

		trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("only")));

		assertThat(contentTypeOf("deck")).isEqualTo(DeckContentType.UNSET);
	}

	/** BR-260 applies to a deleted sub-deck too, not only to deleted cards. */
	@Test
	void returnsTheEmptiedParentOfADeletedSubDeckToUnset() {
		insertRootDeck("root", "Korean");
		insertSubDeck("mid", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("leaf", "Lesson 1", "mid", "root", DeckContentType.UNSET);

		trashDeleteService.deleteDeck(new DeleteDeckCommand("leaf"));

		assertThat(contentTypeOf("mid")).isEqualTo(DeckContentType.UNSET);
	}

	/** BR-58: a root deck holds sub-decks forever, even when it holds none right now. */
	@Test
	void keepsTheRootDeckAsDeckEvenWhenItIsEmptied() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.UNSET);

		trashDeleteService.deleteDeck(new DeleteDeckCommand("a"));

		assertThat(contentTypeOf("root")).isEqualTo(DeckContentType.DECK);
	}

	/**
	 * BR-260: a tombstone still sitting in the deck is not content.
	 *
	 * <p>The deck keeps one card that was already in Trash, so the emptiness test must ignore it
	 * and still drop the deck to unset when the last <em>active</em> card goes.
	 */
	@Test
	void ignoresATombstoneWhenMeasuringWhetherTheDeckIsEmpty() {
		seedCardDeck();
		insertCardWithState("already", "deck", null, null);
		insertCardWithState("last", "deck", null, null);
		softDelete("card", "already");

		trashDeleteService.deleteCards(new DeleteCardsCommand(List.of("last")));

		assertThat(contentTypeOf("deck")).isEqualTo(DeckContentType.UNSET);
	}

	/** A deck already in Trash has no active row, so the caller is describing a database that moved on. */
	@Test
	void refusesToDeleteADeckThatIsAlreadyInTrash() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.UNSET);
		softDelete("deck", "a");

		assertThatThrownBy(() -> trashDeleteService.deleteDeck(new DeleteDeckCommand("a")))
				.isInstanceOf(DeckNotFoundException.class);
	}

	/**
	 * A card already in Trash refuses the whole action, and nothing is written.
	 *
	 * <p>Committing would leave a batch with no rows — a Trash entry the user can see and cannot
	 * act on, because restoring it would revive nothing.
	 */
	@Test
	void refusesTheWholeActionWhenACardIsAlreadyInTrash() {
		seedCardDeck();
		insertCardWithState("live", "deck", null, null);
		insertCardWithState("gone", "deck", null, null);
		softDelete("card", "gone");

		assertThatThrownBy(() -> trashDeleteService.deleteCards(
				new DeleteCardsCommand(List.of("live", "gone"))))
				.isInstanceOf(CardNotFoundException.class);

		assertThat(batchIdOfCard("live")).isNull();
		assertThat(contentTypeOf("deck")).isEqualTo(DeckContentType.CARD);
	}

	private void seedCardDeck() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
	}
}
