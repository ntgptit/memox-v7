package com.memox.deck;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.common.error.ApiErrorCode;
import com.memox.deck.entity.DeckMoveTarget;
import com.memox.deck.enums.DeckContentType;
import com.memox.deck.enums.SchedulerType;
import com.memox.deck.exception.DeckConflictException;
import com.memox.deck.exception.DeckNotFoundException;
import com.memox.deck.service.DeckMoveService;
import com.memox.deck.service.MoveDeckCommand;
import com.memox.deck.service.RenameDeckCommand;
import com.memox.support.PostgresIntegrationTest;

class DeckMoveTest extends PostgresIntegrationTest {

	/** One short of the ceiling, so a two-high subtree moved under it would make eleven. */
	private static final int NEARLY_FULL_CHAIN = 9;

	@Autowired
	private DeckMoveService deckMoveService;

	@Test
	void rewritesRootDeckIdForTheWholeMovedSubtree() {
		insertRootDeck("r1", "Korean", SchedulerType.EIGHT_BOX);
		insertRootDeck("r2", "Japanese", SchedulerType.EIGHT_BOX);
		insertSubDeck("a", "Unit 1", "r1", "r1", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "r1");
		insertSubDeck("target", "Imported", "r2", "r2");

		deckMoveService.move(new MoveDeckCommand("a", "target"));

		assertThat(rootDeckIdOf("a")).isEqualTo("r2");
		assertThat(rootDeckIdOf("b")).isEqualTo("r2");
	}

	/**
	 * The server-side half of translation row 5, which has no Drift counterpart because Drift stores
	 * no {@code sibling_scope_id}. Forgetting it leaves a moved deck competing for positions in its
	 * OLD parent's scope — and the unique constraint would then reject an unrelated write later.
	 */
	@Test
	void rewritesTheSiblingScopeSoTheDeckStopsCompetingInItsOldParent() {
		insertRootDeck("root", "Korean");
		insertSubDeck("old", "Old parent", "root", "root", DeckContentType.DECK);
		insertSubDeck("new", "New parent", "root", "root", DeckContentType.DECK);
		insertSubDeckAt("moved", "Moved", "old", "root", 0);
		insertSubDeckAt("stays", "Stays", "new", "root", 0);

		deckMoveService.move(new MoveDeckCommand("moved", "new"));

		final var scope = this.jdbcTemplate.queryForObject(
				"SELECT sibling_scope_id FROM decks WHERE id = 'moved'", String.class);
		assertThat(scope).isEqualTo("new");
		assertThat(siblingPositionOf("moved")).isEqualTo(1);
	}

	/**
	 * A tombstoned descendant travels with the subtree.
	 *
	 * <p>{@code updateSubtreeRootDeck} deliberately omits {@code delete_batch_id IS NULL} inside its
	 * recursion, copied from Drift. Restoring such a deck later would otherwise put it back under
	 * the root the subtree no longer belongs to.
	 */
	@Test
	void carriesATombstonedDescendantsRootDeckIdAlongWithTheSubtree() {
		insertRootDeck("r1", "Korean");
		insertRootDeck("r2", "Japanese");
		insertSubDeck("a", "Unit 1", "r1", "r1", DeckContentType.DECK);
		insertSubDeck("buried", "Deleted lesson", "a", "r1");
		insertSubDeck("target", "Imported", "r2", "r2");
		softDelete("deck", "buried");

		deckMoveService.move(new MoveDeckCommand("a", "target"));

		assertThat(rootDeckIdOf("buried")).isEqualTo("r2");
	}

	/**
	 * BR-55, and a corrected test.
	 *
	 * <p>The plan's version moved {@code d9} under {@code d10} — but {@code d10} is inside
	 * {@code d9}'s own subtree, so that input violates two rules at once and cannot say which one
	 * answers. This moves a two-high subtree under a deck at depth nine in a different root, where
	 * only the depth rule is broken.
	 */
	@Test
	void refusesAMoveThatWouldMakeAnEleventhLevel() {
		insertChain(NEARLY_FULL_CHAIN);
		insertRootDeck("r2", "Japanese");
		insertSubDeck("a", "Unit 1", "r2", "r2", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "r2");

		assertThatThrownBy(() -> deckMoveService.move(new MoveDeckCommand("a", "d9")))
				.isInstanceOf(DeckConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.DECK_DEPTH_EXCEEDED);
	}

	@Test
	void allowsAMoveThatLandsExactlyOnTheTenthLevel() {
		insertChain(NEARLY_FULL_CHAIN);
		insertRootDeck("r2", "Japanese");
		insertSubDeck("leaf", "Unit 1", "r2", "r2");

		deckMoveService.move(new MoveDeckCommand("leaf", "d9"));

		assertThat(rootDeckIdOf("leaf")).isEqualTo("d1");
	}

	@Test
	void refusesAMoveIntoTheDecksOwnSubtree() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root");

		assertThatThrownBy(() -> deckMoveService.move(new MoveDeckCommand("a", "b")))
				.isInstanceOf(DeckConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.DECK_MOVE_INTO_OWN_SUBTREE);
	}

	@Test
	void refusesAMoveOntoItself() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root");

		assertThatThrownBy(() -> deckMoveService.move(new MoveDeckCommand("a", "a")))
				.isInstanceOf(DeckConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.DECK_MOVE_INTO_OWN_SUBTREE);
	}

	@Test
	void refusesACrossRootMoveWhenTheGenerationDiffers() {
		insertRootDeck("r1", "Korean", SchedulerType.EIGHT_BOX, 1);
		insertRootDeck("r2", "Japanese", SchedulerType.EIGHT_BOX, 2);
		insertSubDeck("a", "Unit 1", "r1", "r1");
		insertSubDeck("target", "Imported", "r2", "r2");

		assertThatThrownBy(() -> deckMoveService.move(new MoveDeckCommand("a", "target")))
				.isInstanceOf(DeckConflictException.class)
				.extracting("errorCode")
				.isEqualTo(ApiErrorCode.SCHEDULER_GENERATION_MISMATCH);
	}

	/** BR-73/74: a differing scheduler is refused, never silently converted. */
	@Test
	void refusesACrossRootMoveWhenTheSchedulerTypeDiffers() {
		insertRootDeck("r1", "Korean", SchedulerType.EIGHT_BOX);
		insertRootDeck("r2", "Japanese", SchedulerType.SM2);
		insertSubDeck("a", "Unit 1", "r1", "r1");
		insertSubDeck("target", "Imported", "r2", "r2");

		assertThatThrownBy(() -> deckMoveService.move(new MoveDeckCommand("a", "target")))
				.isInstanceOf(DeckConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.DECK_CROSS_ROOT_MOVE);
	}

	/** BR-163: emptying a sub-deck puts it back to unset, in the same transaction as the move. */
	@Test
	void dropsTheOldParentBackToUnsetWhenItLosesItsLastChild() {
		insertRootDeck("root", "Korean");
		insertSubDeck("old", "Old parent", "root", "root", DeckContentType.DECK);
		insertSubDeck("new", "New parent", "root", "root", DeckContentType.DECK);
		insertSubDeck("only", "Only child", "old", "root");

		deckMoveService.move(new MoveDeckCommand("only", "new"));

		assertThat(contentTypeOf("old")).isEqualTo(DeckContentType.UNSET);
	}

	@Test
	void keepsTheOldParentAsDeckWhenItStillHasAnotherChild() {
		insertRootDeck("root", "Korean");
		insertSubDeck("old", "Old parent", "root", "root", DeckContentType.DECK);
		insertSubDeck("new", "New parent", "root", "root", DeckContentType.DECK);
		insertSubDeck("moving", "Moving", "old", "root");
		insertSubDeck("staying", "Staying", "old", "root");

		deckMoveService.move(new MoveDeckCommand("moving", "new"));

		assertThat(contentTypeOf("old")).isEqualTo(DeckContentType.DECK);
	}

	/** BR-260: the new parent commits to holding decks the moment it receives one. */
	@Test
	void raisesAnUnsetNewParentToHoldingDecks() {
		insertRootDeck("root", "Korean");
		insertSubDeck("old", "Old parent", "root", "root", DeckContentType.DECK);
		insertSubDeck("new", "New parent", "root", "root", DeckContentType.UNSET);
		insertSubDeck("moving", "Moving", "old", "root");

		deckMoveService.move(new MoveDeckCommand("moving", "new"));

		assertThat(contentTypeOf("new")).isEqualTo(DeckContentType.DECK);
	}

	@Test
	void refusesAMoveIntoADeckThatHoldsCards() {
		insertRootDeck("root", "Korean");
		insertSubDeck("cards", "Card holder", "root", "root", DeckContentType.CARD);
		insertSubDeck("moving", "Moving", "root", "root");

		assertThatThrownBy(() -> deckMoveService.move(new MoveDeckCommand("moving", "cards")))
				.isInstanceOf(DeckConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.PARENT_HOLDS_CARDS);
	}

	@Test
	void renamesADeckAndTrimsTheName() {
		insertRootDeck("root", "Korean");

		final var renamed = deckMoveService.rename(new RenameDeckCommand("root", "  Korean basics  "));

		assertThat(renamed.name()).isEqualTo("Korean basics");
		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT name FROM decks WHERE id = 'root'", String.class)).isEqualTo("Korean basics");
	}

	@Test
	void refusesToRenameADeckThatIsGone() {
		assertThatThrownBy(() -> deckMoveService.rename(new RenameDeckCommand("nope", "Anything")))
				.isInstanceOf(DeckNotFoundException.class);
	}

	/**
	 * Card move targets are decks that can hold cards: not the root, not the source, and not one
	 * that has already committed to holding sub-decks.
	 */
	@Test
	void listsOnlyDecksThatCouldAcceptCards() {
		insertRootDeck("root", "Korean");
		insertSubDeck("source", "Source", "root", "root", DeckContentType.CARD);
		insertSubDeck("empty", "Empty", "root", "root", DeckContentType.UNSET);
		insertSubDeck("cards", "Holds cards", "root", "root", DeckContentType.CARD);
		insertSubDeck("decks", "Holds decks", "root", "root", DeckContentType.DECK);
		insertSubDeck("gone", "Deleted", "root", "root", DeckContentType.UNSET);
		softDelete("deck", "gone");

		final var targets = deckMoveService.listCardMoveTargets("root", "source");

		// Ordered by name, not by id: "Empty" sorts before "Holds cards".
		assertThat(targets).extracting(DeckMoveTarget::deckId).containsExactly("empty", "cards");
		assertThat(targets).extracting(DeckMoveTarget::parentName).containsOnly("Korean");
	}
}
