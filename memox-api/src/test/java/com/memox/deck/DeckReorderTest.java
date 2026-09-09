package com.memox.deck;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.common.error.ApiErrorCode;
import com.memox.deck.entity.Deck;
import com.memox.deck.exception.DeckConflictException;
import com.memox.deck.exception.DeckNotFoundException;
import com.memox.deck.service.DeckService;
import com.memox.deck.service.ReorderDeckCommand;
import com.memox.support.PostgresIntegrationTest;

class DeckReorderTest extends PostgresIntegrationTest {

	@Autowired
	private DeckService deckService;

	@Test
	void movesADeckDownAndClosesTheGapItLeaves() {
		insertRootDeck("root", "Korean");
		insertSubDeckAt("a", "A", "root", "root", 0);
		insertSubDeckAt("b", "B", "root", "root", 1);
		insertSubDeckAt("c", "C", "root", "root", 2);

		final var group = deckService.reorderDeck(new ReorderDeckCommand("a", 2));

		assertThat(group).extracting(Deck::id).containsExactly("b", "c", "a");
		assertThat(group).extracting(Deck::siblingPosition).containsExactly(0, 1, 2);
	}

	@Test
	void movesADeckUpAndPushesTheOthersDown() {
		insertRootDeck("root", "Korean");
		insertSubDeckAt("a", "A", "root", "root", 0);
		insertSubDeckAt("b", "B", "root", "root", 1);
		insertSubDeckAt("c", "C", "root", "root", 2);

		final var group = deckService.reorderDeck(new ReorderDeckCommand("c", 0));

		assertThat(group).extracting(Deck::id).containsExactly("c", "a", "b");
	}

	@Test
	void treatsAMoveToTheSamePositionAsANoOp() {
		insertRootDeck("root", "Korean");
		insertSubDeckAt("a", "A", "root", "root", 0);
		insertSubDeckAt("b", "B", "root", "root", 1);

		final var group = deckService.reorderDeck(new ReorderDeckCommand("a", 0));

		assertThat(group).extracting(Deck::id).containsExactly("a", "b");
	}

	@Test
	void reordersRootDecksToo() {
		insertRootDeck("first", "Korean");
		insertRootDeck("second", "Japanese");

		final var group = deckService.reorderDeck(new ReorderDeckCommand("second", 0));

		assertThat(group).extracting(Deck::id).containsExactly("second", "first");
	}

	@Test
	void rejectsATargetPositionOutsideTheSiblingGroup() {
		insertRootDeck("root", "Korean");
		insertSubDeckAt("a", "A", "root", "root", 0);

		assertThatThrownBy(() -> deckService.reorderDeck(new ReorderDeckCommand("a", 3)))
				.isInstanceOf(DeckConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.DECK_POSITION_OUT_OF_RANGE);
	}

	@Test
	void rejectsANegativeTargetPosition() {
		insertRootDeck("root", "Korean");
		insertSubDeckAt("a", "A", "root", "root", 0);

		assertThatThrownBy(() -> deckService.reorderDeck(new ReorderDeckCommand("a", -1)))
				.isInstanceOf(DeckConflictException.class);
	}

	@Test
	void rejectsReorderingADeckThatIsGone() {
		assertThatThrownBy(() -> deckService.reorderDeck(new ReorderDeckCommand("nope", 0)))
				.isInstanceOf(DeckNotFoundException.class);
	}

	/**
	 * The test that decides the algorithm.
	 *
	 * <p>A soft-deleted sibling keeps its {@code sibling_position} row, so it still occupies a slot
	 * in {@code uq_decks_sibling_scope_position} — but it must not occupy a slot in the order a user
	 * sees (BR-257, BR-268).
	 *
	 * <p>Renumbering the active siblings densely from 0, as the plan described, puts {@code c} at
	 * position 1 where the tombstone already sits. A deferred constraint makes a <em>transient</em>
	 * collision legal; this one survives to COMMIT, so it is simply a violation. The reorder instead
	 * <strong>permutes the positions the active siblings already own</strong> — here {0, 2} — which
	 * leaves the tombstone's slot alone and still needs the deferred constraint for the swap in
	 * between.
	 */
	@Test
	void ignoresSoftDeletedSiblingsWhenRenumbering() {
		insertRootDeck("root", "Korean");
		insertSubDeckAt("a", "A", "root", "root", 0);
		insertSubDeckAt("gone", "Gone", "root", "root", 1);
		insertSubDeckAt("c", "C", "root", "root", 2);
		softDelete("deck", "gone");

		final var group = deckService.reorderDeck(new ReorderDeckCommand("c", 0));

		assertThat(group).extracting(Deck::id).containsExactly("c", "a");
		assertThat(group).extracting(Deck::siblingPosition).containsExactly(0, 2);
		assertThat(siblingPositionOf("gone")).isEqualTo(1);
	}

	/**
	 * The reorder passes through a state where two siblings share a position, which is only legal
	 * because V5 made the constraint DEFERRABLE INITIALLY DEFERRED. Any swap exercises it; this one
	 * says so out loud.
	 */
	@Test
	void survivesTheTransientCollisionASwapMustPassThrough() {
		insertRootDeck("root", "Korean");
		insertSubDeckAt("a", "A", "root", "root", 0);
		insertSubDeckAt("b", "B", "root", "root", 1);

		final var group = deckService.reorderDeck(new ReorderDeckCommand("b", 0));

		assertThat(group).extracting(Deck::id, Deck::siblingPosition)
				.containsExactly(org.assertj.core.groups.Tuple.tuple("b", 0),
						org.assertj.core.groups.Tuple.tuple("a", 1));
	}
}
