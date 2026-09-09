package com.memox.deck;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.deck.enums.DeckContentType;
import com.memox.deck.service.DeckStructureService;
import com.memox.support.PostgresIntegrationTest;

class DeckStructureTest extends PostgresIntegrationTest {

	@Autowired
	private DeckStructureService deckStructureService;

	/** BR-55: the root is level 1, not level 0. Every depth rule counts from there. */
	@Test
	void reportsRootDepthAsOne() {
		insertRootDeck("root", "Korean");

		assertThat(deckStructureService.depthOf("root")).isEqualTo(1);
	}

	@Test
	void reportsTheTenthLevelAsTen() {
		insertChain(10);

		assertThat(deckStructureService.depthOf("d10")).isEqualTo(10);
		assertThat(deckStructureService.depthOf("d5")).isEqualTo(5);
	}

	@Test
	void reportsSubtreeHeightFromTheGivenNode() {
		insertChain(4);

		assertThat(deckStructureService.subtreeHeight("d2")).isEqualTo(3);
		assertThat(deckStructureService.subtreeHeight("d4")).isEqualTo(1);
	}

	@Test
	void countsOnlyActiveCardsInASubtree() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.CARD);
		insertCardWithState("kept", "b", null, null);
		insertCardWithState("trashed", "b", null, null);
		softDelete("card", "trashed");

		assertThat(deckStructureService.subtreeCardCount("a")).isEqualTo(1);
	}

	@Test
	void separatesDirectCountsFromSubtreeCounts() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.CARD);
		insertSubDeck("c", "Lesson 2", "a", "root", DeckContentType.CARD);
		insertCardWithState("in-b", "b", null, null);
		insertCardWithState("in-c", "c", null, null);

		assertThat(deckStructureService.directChildDeckCount("a")).isEqualTo(2);
		assertThat(deckStructureService.directCardCount("a")).isZero();
		assertThat(deckStructureService.subtreeCardCount("a")).isEqualTo(2);
	}

	/** The subtree includes the deck itself — a move or a delete acts on the whole set. */
	@Test
	void listsTheSubtreeIncludingTheDeckItselfAndExcludingTrashedBranches() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root");
		insertSubDeck("gone", "Lesson 2", "a", "root");
		softDelete("deck", "gone");

		assertThat(deckStructureService.subtreeDeckIds("a")).containsExactlyInAnyOrder("a", "b");
	}

	@Test
	void reportsNothingForADeckThatIsItselfSoftDeleted() {
		insertRootDeck("root", "Korean");
		softDelete("deck", "root");

		assertThat(deckStructureService.depthOf("root")).isZero();
		assertThat(deckStructureService.subtreeHeight("root")).isZero();
		assertThat(deckStructureService.subtreeDeckIds("root")).isEmpty();
	}

	/**
	 * The walk observes an eleventh level rather than stopping at ten.
	 *
	 * <p>{@code MAX_WALK = MAX_TREE_DEPTH + 1} exists for exactly this: a probe capped at ten cannot
	 * tell "exactly at the limit" from "past it", and the depth rule has to reject the second while
	 * accepting the first.
	 */
	@Test
	void seesTheEleventhLevelSoTheDepthRuleCanRejectIt() {
		insertChain(11);

		assertThat(deckStructureService.depthOf("d11")).isEqualTo(11);
	}

	/**
	 * A chain longer than the walk reports a truncated depth, not a wrong one.
	 *
	 * <p>Only corrupt data can produce this — BR-55 caps a real tree at ten — and a truncated answer
	 * that is still above the limit refuses the write just as a complete one would. What must not
	 * happen is the walk running forever.
	 */
	@Test
	void truncatesRatherThanRunsForeverOnAChainLongerThanTheWalk() {
		insertChain(14);

		assertThat(deckStructureService.depthOf("d14")).isEqualTo(11);
	}

	@Test
	void stopsWalkingADepthProbeThatCyclesInsteadOfRunningForever() {
		insertRootDeck("a", "A");
		insertRootDeck("b", "B");
		this.jdbcTemplate.update("UPDATE decks SET parent_deck_id = 'b', sibling_scope_id = 'b' WHERE id = 'a'");
		this.jdbcTemplate.update("UPDATE decks SET parent_deck_id = 'a', sibling_scope_id = 'a' WHERE id = 'b'");

		assertThat(deckStructureService.depthOf("a")).isEqualTo(11);
	}
}
