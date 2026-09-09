package com.memox.deck.entity;

import java.time.Instant;

import com.memox.deck.enums.SchedulerType;

/**
 * One direct child of a deck, carrying the aggregate of its <em>whole</em> subtree.
 *
 * <p>That is what makes the level view the same idea as the Library list rather than a plainer one:
 * opening a deck shows the same three facts about each child that the root list shows about each
 * root. The counts come from a recursive walk, because no column identifies an intermediate
 * ancestor the way {@code root_deck_id} identifies a root.
 *
 * <p>Two fields are deliberately not what they look like:
 *
 * <ul>
 *   <li>{@code subDeckCount} is a <strong>direct</strong>-child count, not a subtree count — the
 *       one aggregate here that is not keyed on the recursive walk, exactly as in Drift.</li>
 *   <li>{@code inheritedSchedulerType} comes from the root, because a sub-deck's own scheduler
 *       columns are NULL by rule and the review it takes part in uses the root's (BR-06). Reading
 *       it here keeps the level one statement instead of one plus a lookup.</li>
 * </ul>
 *
 * <p>There is no {@code nextDueAt} on a child. That instant is scoped to the level as a whole and
 * lives on {@link DeckLevel}; see the note there.
 */
public record DeckLevelChild(
		Deck child,
		SchedulerType inheritedSchedulerType,
		long totalCardCount,
		long newCardCount,
		long dueCardCount,
		long overdueCardCount,
		Instant oldestDueAt,
		long learnedCardCount,
		long subDeckCount) {
}
