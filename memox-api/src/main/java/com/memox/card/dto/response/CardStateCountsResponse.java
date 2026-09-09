package com.memox.card.dto.response;

import com.memox.card.entity.CardStateCounts;

/** The four stage counts of a deck. They partition its active cards, so they sum to its total. */
public record CardStateCountsResponse(
		long newCount,
		long learningCount,
		long reviewingCount,
		long masteredCount) {

	public static CardStateCountsResponse from(CardStateCounts counts) {
		return new CardStateCountsResponse(counts.newCount(), counts.learningCount(),
				counts.reviewingCount(), counts.masteredCount());
	}
}
