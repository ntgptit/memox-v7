package com.memox.card.entity;

/**
 * How many cards of a deck sit in each learning stage.
 *
 * <p>The four numbers partition the deck's active cards, so they sum to its total. A card is new
 * until it has been learned, then moves through the stages by box (eight-box) or by interval (SM-2)
 * — two schedulers, one set of counts, decided by the thresholds the caller supplies rather than by
 * literals inside the statement.
 */
public record CardStateCounts(
		long newCount,
		long learningCount,
		long reviewingCount,
		long masteredCount) {
}
