package com.memox.deck;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.tuple;

import java.time.Instant;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.deck.entity.DeckAncestor;
import com.memox.deck.entity.DeckLevelChild;
import com.memox.deck.enums.DeckContentType;
import com.memox.deck.enums.SchedulerType;
import com.memox.deck.service.DeckTreeService;
import com.memox.support.PostgresIntegrationTest;

class DeckLevelTest extends PostgresIntegrationTest {

	private static final Instant NOW = Instant.parse("2026-09-09T12:00:00Z");
	private static final Instant START_OF_TODAY = Instant.parse("2026-09-09T00:00:00Z");
	private static final Instant LEARNED = Instant.parse("2026-09-01T00:00:00Z");

	@Autowired
	private DeckTreeService deckTreeService;

	/** Translation row 2: an empty ancestry is {@code []}, never null. */
	@Test
	void returnsAnEmptyAncestryListForAFirstLevelParent() {
		insertRootDeck("root", "Korean");
		insertSubDeck("level2", "Unit 1", "root", "root");

		final var level = deckTreeService.readLevel("root", NOW, START_OF_TODAY);

		assertThat(level.parent().ancestry()).isEmpty();
		assertThat(level.parent().deckName()).isEqualTo("Korean");
		assertThat(level.children()).singleElement()
				.extracting(child -> child.child().id()).isEqualTo("level2");
	}

	/**
	 * A child's counts cover its whole subtree, which is what the recursive {@code branch} CTE is
	 * for. No column identifies an intermediate ancestor, so this cannot be a flat GROUP BY the way
	 * the root summaries can.
	 */
	@Test
	void countsACardThatSitsTwoLevelsBelowTheChild() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.DECK);
		insertSubDeck("c", "Set 1", "b", "root", DeckContentType.CARD);
		insertCardWithState("card-1", "c", null, null);

		final var level = deckTreeService.readLevel("root", NOW, START_OF_TODAY);

		assertThat(level.children()).singleElement()
				.extracting(DeckLevelChild::totalCardCount, DeckLevelChild::newCardCount)
				.containsExactly(1L, 1L);
	}

	/** {@code subDeckCount} is deliberately NOT branch-keyed: it counts direct children only. */
	@Test
	void countsOnlyDirectChildrenAsSubDecks() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root", DeckContentType.DECK);
		insertSubDeck("c", "Set 1", "b", "root");

		final var level = deckTreeService.readLevel("root", NOW, START_OF_TODAY);

		assertThat(level.children()).singleElement()
				.extracting(DeckLevelChild::subDeckCount).isEqualTo(1L);
	}

	@Test
	void reportsTheAncestryOfADeepParentNearestFirst() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("b", "Lesson 1", "a", "root");

		final var level = deckTreeService.readLevel("b", NOW, START_OF_TODAY);

		assertThat(level.parent().ancestry())
				.extracting(DeckAncestor::id, DeckAncestor::distance)
				.containsExactly(tuple("a", 1), tuple("root", 2));
	}

	/**
	 * The scheduler comes from the root (BR-06): a sub-deck's own scheduler columns are NULL by
	 * rule, and the review it takes part in uses the root's.
	 */
	@Test
	void reportsTheSchedulerInheritedFromTheRoot() {
		insertRootDeck("root", "Korean", SchedulerType.SM2);
		insertSubDeck("child", "Unit 1", "root", "root");

		final var level = deckTreeService.readLevel("root", NOW, START_OF_TODAY);

		assertThat(level.children()).singleElement().satisfies(child -> {
			assertThat(child.child().schedulerType()).isNull();
			assertThat(child.inheritedSchedulerType()).isEqualTo(SchedulerType.SM2);
		});
	}

	/**
	 * {@code nextDueAt} belongs to the level, not to a child — and its horizon is this level's
	 * subtrees, not the whole database.
	 *
	 * <p>Drift scopes it to the {@code branch} CTE deliberately: a card scheduled in some unrelated
	 * tree changing state does not move any number on this screen, so waking the controller for it
	 * would re-run the query for a snapshot guaranteed identical. The plan told this task to
	 * restrict the scalar to {@code child.id}; that would repeat the per-row mistake PR #517
	 * reverted one level up, so the sub-select is ported unchanged and the value hangs off
	 * {@code DeckLevel} where its meaning is honest.
	 */
	@Test
	void scopesNextDueAtToTheLevelAndIgnoresUnrelatedTrees() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.CARD);
		insertSubDeck("b", "Unit 2", "root", "root", DeckContentType.CARD);
		insertCardWithState("in-a", "a", LEARNED, Instant.parse("2026-10-31T00:00:00Z"));
		insertCardWithState("in-b", "b", LEARNED, Instant.parse("2026-09-20T00:00:00Z"));

		insertRootDeck("elsewhere", "Japanese");
		insertSubDeck("far", "Unit", "elsewhere", "elsewhere", DeckContentType.CARD);
		insertCardWithState("sooner", "far", LEARNED, Instant.parse("2026-09-11T00:00:00Z"));

		final var level = deckTreeService.readLevel("root", NOW, START_OF_TODAY);

		assertThat(level.nextDueAt()).isEqualTo(Instant.parse("2026-09-20T00:00:00Z"));
	}

	/**
	 * A parent with no children yields one row whose child columns are all NULL, because the join
	 * is a LEFT JOIN. That row is not a child and must not become one.
	 */
	@Test
	void returnsNoChildrenForAParentThatHasNone() {
		insertRootDeck("root", "Korean");

		final var level = deckTreeService.readLevel("root", NOW, START_OF_TODAY);

		assertThat(level.parent().deckName()).isEqualTo("Korean");
		assertThat(level.children()).isEmpty();
		assertThat(level.nextDueAt()).isNull();
	}

	@Test
	void leavesASoftDeletedChildOutOfTheLevel() {
		insertRootDeck("root", "Korean");
		insertSubDeck("kept", "Unit 1", "root", "root");
		insertSubDeck("gone", "Unit 2", "root", "root");
		softDelete("deck", "gone");

		final var level = deckTreeService.readLevel("root", NOW, START_OF_TODAY);

		assertThat(level.children()).extracting(child -> child.child().id()).containsExactly("kept");
	}

	@Test
	void returnsNothingForADeckThatIsItselfSoftDeleted() {
		insertRootDeck("root", "Korean");
		softDelete("deck", "root");

		assertThat(deckTreeService.readLevel("root", NOW, START_OF_TODAY)).isNull();
	}

	/** {@code deckContextById}: the card list header — the deck's own name plus the path above it. */
	@Test
	void readsADecksOwnNameAndThePathAboveIt() {
		insertChain(4);

		final var context = deckTreeService.readContext("d4");

		assertThat(context.deckId()).isEqualTo("d4");
		assertThat(context.deckName()).isEqualTo("Level 4");
		assertThat(context.contentType()).isEqualTo(DeckContentType.UNSET);
		assertThat(context.ancestry()).extracting(DeckAncestor::id, DeckAncestor::name)
				.containsExactly(tuple("d3", "Level 3"), tuple("d2", "Level 2"), tuple("d1", "Level 1"));
	}

	/** The deck itself is never in its own ancestry — it is the title, and the path is the crumbs. */
	@Test
	void keepsTheDeckItselfOutOfItsOwnAncestry() {
		insertChain(3);

		assertThat(deckTreeService.readContext("d3").ancestry())
				.extracting(DeckAncestor::id).doesNotContain("d3");
	}

	@Test
	void returnsNothingForTheContextOfASoftDeletedDeck() {
		insertRootDeck("root", "Korean");
		softDelete("deck", "root");

		assertThat(deckTreeService.readContext("root")).isNull();
	}

	/**
	 * The walk terminates on corrupt cyclic data, and this is the divergence that matters most.
	 *
	 * <p>Drift's {@code deckContextById} carries no depth bound and its comment claims UNION makes
	 * it safe. {@code deck.drift} refutes exactly that, beside the identical CTE in
	 * {@code childDeckLevel}: "its {@code distance} grows on every lap, so every row stays distinct
	 * and UNION cannot deduplicate it". So the port carries the same {@code maxWalk} bound both
	 * statements need. Without it this test does not fail — it hangs.
	 */
	@Test
	void stopsWalkingAnAncestryThatCyclesInsteadOfRunningForever() {
		insertRootDeck("a", "A");
		insertRootDeck("b", "B");
		this.jdbcTemplate.update("UPDATE decks SET parent_deck_id = 'b', sibling_scope_id = 'b' WHERE id = 'a'");
		this.jdbcTemplate.update("UPDATE decks SET parent_deck_id = 'a', sibling_scope_id = 'a' WHERE id = 'b'");

		final var context = deckTreeService.readContext("a");

		assertThat(context.ancestry()).hasSizeLessThanOrEqualTo(11);
	}
}
