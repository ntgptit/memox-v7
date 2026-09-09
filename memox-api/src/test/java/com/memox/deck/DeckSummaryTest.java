package com.memox.deck;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.common.pagination.PageQuery;
import com.memox.deck.entity.Deck;
import com.memox.deck.entity.DeckSummary;
import com.memox.deck.enums.DeckContentType;
import com.memox.deck.enums.DeckSortField;
import com.memox.deck.service.DeckTreeService;
import com.memox.support.PostgresIntegrationTest;

class DeckSummaryTest extends PostgresIntegrationTest {

	private static final Instant NOW = Instant.parse("2026-09-09T12:00:00Z");
	private static final Instant START_OF_TODAY = Instant.parse("2026-09-09T00:00:00Z");

	@Autowired
	private DeckTreeService deckTreeService;

	/**
	 * Counts reach the root through {@code root_deck_id}, not by walking parents.
	 *
	 * <p>This is the difference {@code COALESCE(parent_deck_id, id)} gets wrong from the third
	 * level down, which is why the repo forbids it. A card three levels deep must still be counted
	 * by its root.
	 */
	@Test
	void countsCardsThroughTheRootDeckAndNotThroughTheImmediateParent() {
		insertRootDeck("root", "Korean");
		insertSubDeck("level2", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("level3", "Lesson 1", "level2", "root", DeckContentType.CARD);
		insertCardWithState("card-1", "level3", null, null);

		final var page = deckTreeService.listRootSummaries(pageQuery(), NOW, START_OF_TODAY);

		assertThat(page.getItems()).singleElement().satisfies(summary -> {
			assertThat(summary.id()).isEqualTo("root");
			assertThat(summary.totalCardCount()).isEqualTo(1);
			assertThat(summary.newCardCount()).isEqualTo(1);
			assertThat(summary.dueCardCount()).isZero();
			assertThat(summary.subDeckCount()).isEqualTo(1);
		});
	}

	/** BR-257: a soft-deleted card is gone from every count, not merely from the list. */
	@Test
	void excludesSoftDeletedCardsFromEveryCount() {
		insertRootDeck("root", "Korean");
		insertSubDeck("level2", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState("kept", "level2", null, null);
		insertCardWithState("trashed", "level2", null, null);
		softDelete("card", "trashed");

		final var page = deckTreeService.listRootSummaries(pageQuery(), NOW, START_OF_TODAY);

		assertThat(page.getItems()).singleElement()
				.extracting(DeckSummary::totalCardCount, DeckSummary::newCardCount)
				.containsExactly(1L, 1L);
	}

	/**
	 * Due, overdue and oldest-due all read the same window, and a new card is in none of them.
	 *
	 * <p>"Due" needs {@code learned_at IS NOT NULL} as well as a past {@code due_at}: a card that
	 * has never been learned is new, and counting it as due would put it in two buckets at once
	 * (BR-90, BR-151).
	 */
	@Test
	void separatesNewFromDueAndCountsOnlyYesterdaysAsOverdue() {
		insertRootDeck("root", "Korean");
		insertSubDeck("cards", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState("brand-new", "cards", null, null);
		insertCardWithState("due-today", "cards", Instant.parse("2026-09-01T00:00:00Z"), START_OF_TODAY);
		insertCardWithState("overdue", "cards", Instant.parse("2026-09-01T00:00:00Z"),
				Instant.parse("2026-09-07T00:00:00Z"));

		final var page = deckTreeService.listRootSummaries(pageQuery(), NOW, START_OF_TODAY);

		assertThat(page.getItems()).singleElement().satisfies(summary -> {
			assertThat(summary.totalCardCount()).isEqualTo(3);
			assertThat(summary.newCardCount()).isEqualTo(1);
			assertThat(summary.dueCardCount()).isEqualTo(2);
			assertThat(summary.overdueCardCount()).isEqualTo(1);
			assertThat(summary.oldestDueAt()).isEqualTo(Instant.parse("2026-09-07T00:00:00Z"));
		});
	}

	/**
	 * {@code nextDueAt} is one number for the whole page, repeated on every row, and that is the
	 * design rather than a missing correlation.
	 *
	 * <p>It answers "when would any count on this screen next change", and the list schedules its
	 * re-measure from it. A per-root value would make the screen wake at the first tree's boundary
	 * and be late for every other tree. Drift states it and adds the cost: one scalar subquery,
	 * evaluated once per statement rather than once per row.
	 *
	 * <p>This test exists because the opposite was implemented and merged first, on the strength of
	 * the plan calling the missing correlation a bug. Two roots with different future due dates is
	 * the arrangement where the two readings disagree, so it is the arrangement that pins which one
	 * this API promises.
	 */
	@Test
	void reportsOneNextDueAtForTheWholePageBecauseItIsTheScreensReMeasureTimer() {
		insertRootDeck("early", "Korean");
		insertSubDeck("early-cards", "Unit", "early", "early", DeckContentType.CARD);
		insertCardWithState("soon", "early-cards", Instant.parse("2026-09-01T00:00:00Z"),
				Instant.parse("2026-09-20T00:00:00Z"));

		insertRootDeck("late", "Japanese");
		insertSubDeck("late-cards", "Unit", "late", "late", DeckContentType.CARD);
		insertCardWithState("later", "late-cards", Instant.parse("2026-09-01T00:00:00Z"),
				Instant.parse("2026-10-31T00:00:00Z"));

		final var summaries = deckTreeService.listRootSummaries(pageQuery(), NOW, START_OF_TODAY).getItems();

		assertThat(summaries).hasSize(2)
				.extracting(DeckSummary::nextDueAt)
				.containsOnly(Instant.parse("2026-09-20T00:00:00Z"));
	}

	/**
	 * The one real divergence: a card whose DECK is in Trash must not set the wake-up moment either.
	 *
	 * <p>Drift joins {@code cards} alone, so it drops a trashed card but keeps a card sitting in a
	 * trashed deck — while every count beside it checks the deck's tombstone. The port applies
	 * Drift's own stated reason to both cases (BR-257): the state row survives a soft delete by
	 * design, and without this the screen schedules a re-measure for a card no count includes.
	 */
	@Test
	void ignoresCardsInATrashedDeckWhenSchedulingTheNextReMeasure() {
		insertRootDeck("root", "Korean");
		insertSubDeck("kept", "Unit A", "root", "root", DeckContentType.CARD);
		insertSubDeck("trashed", "Unit B", "root", "root", DeckContentType.CARD);
		insertCardWithState("far", "kept", Instant.parse("2026-09-01T00:00:00Z"),
				Instant.parse("2026-10-31T00:00:00Z"));
		insertCardWithState("near", "trashed", Instant.parse("2026-09-01T00:00:00Z"),
				Instant.parse("2026-09-20T00:00:00Z"));
		softDelete("deck", "trashed");

		final var summaries = deckTreeService.listRootSummaries(pageQuery(), NOW, START_OF_TODAY).getItems();

		assertThat(summaries).singleElement()
				.extracting(DeckSummary::nextDueAt)
				.isEqualTo(Instant.parse("2026-10-31T00:00:00Z"));
	}

	/**
	 * Every descendant carries the root's id, so the subtree needs no recursion (BR-56).
	 *
	 * <p>Membership, not order: Drift's {@code decksInTree} orders by
	 * {@code sibling_position, id} — a flat ordering the client rebuilds a tree from using the
	 * parent pointers already in these rows. It is deliberately not depth-first, and the port keeps
	 * that. The ordering that does carry meaning is asserted in
	 * {@link #ordersASubtreeBySiblingPositionExactlyAsDriftDoes()}.
	 */
	@Test
	void returnsTheWholeTreeOfOneRootAndNothingFromAnother() {
		insertRootDeck("root", "Korean");
		insertSubDeck("child", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("grandchild", "Lesson 1", "child", "root");
		insertRootDeck("other", "Japanese");

		assertThat(deckTreeService.listTree("root")).extracting(Deck::id)
				.containsExactlyInAnyOrder("root", "child", "grandchild");
		assertThat(deckTreeService.listAllActive()).extracting(Deck::id)
				.contains("root", "child", "grandchild", "other");
	}

	@Test
	void ordersASubtreeBySiblingPositionExactlyAsDriftDoes() {
		insertRootDeck("root", "Korean");
		insertSubDeckAt("third", "C", "root", "root", 2);
		insertSubDeckAt("first", "A", "root", "root", 0);
		insertSubDeckAt("second", "B", "root", "root", 1);

		// containsSubsequence, not containsExactly: the root shares position 0 with its first child
		// (positions are per-parent), so where the root itself lands depends on id ordering and is
		// not the claim. The claim is that siblings come back in sibling_position order.
		assertThat(deckTreeService.listTree("root")).extracting(Deck::id)
				.containsSubsequence("first", "second", "third");
	}

	@Test
	void leavesASoftDeletedDeckOutOfBothTreeReads() {
		insertRootDeck("root", "Korean");
		insertSubDeck("child", "Unit 1", "root", "root");
		softDelete("deck", "child");

		assertThat(deckTreeService.listTree("root")).extracting(Deck::id)
				.containsExactly("root");
		assertThat(deckTreeService.listAllActive()).extracting(Deck::id)
				.doesNotContain("child");
	}

	private PageQuery<DeckSortField> pageQuery() {
		return PageQuery.<DeckSortField>builder().build();
	}
}
