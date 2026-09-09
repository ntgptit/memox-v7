package com.memox.deck.dto.response;

import java.time.Instant;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.memox.deck.entity.DeckSummary;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record DeckSummaryResponse(
		String id,
		String name,
		String rootDeckId,
		String contentType,
		String schedulerType,
		int siblingPosition,
		long totalCardCount,
		long newCardCount,
		long dueCardCount,
		long overdueCardCount,
		Instant oldestDueAt,
		long learnedCardCount,
		long subDeckCount,
		Instant nextDueAt,
		Instant createdAt,
		Instant updatedAt) {

	public static DeckSummaryResponse from(DeckSummary summary) {
		return new DeckSummaryResponse(summary.id(), summary.name(), summary.rootDeckId(),
				summary.contentType().getValue(), schedulerValue(summary), summary.siblingPosition(),
				summary.totalCardCount(), summary.newCardCount(), summary.dueCardCount(),
				summary.overdueCardCount(), summary.oldestDueAt(), summary.learnedCardCount(),
				summary.subDeckCount(), summary.nextDueAt(), summary.createdAt(), summary.updatedAt());
	}

	private static String schedulerValue(DeckSummary summary) {
		if (summary.schedulerType() == null) {
			return null;
		}
		return summary.schedulerType().getValue();
	}
}
