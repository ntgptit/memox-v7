package com.memox.card.dto.response;

import java.time.Instant;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.memox.card.entity.CardHistoryEntry;

/** One recorded answer, every stored column of it (BR-242). */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record CardHistoryEntryResponse(
		String id,
		String cardId,
		String sessionId,
		String schedulerType,
		int schedulerGeneration,
		String kind,
		String mode,
		String outcomeReason,
		Integer comparisonVersion,
		Boolean usedHint,
		String action,
		Instant answeredAt,
		Instant nextDueAt,
		Integer previousBox,
		Integer nextBox,
		Double previousEaseFactor,
		Double nextEaseFactor,
		Integer previousIntervalDays,
		Integer nextIntervalDays,
		String direction) {

	public static CardHistoryEntryResponse from(CardHistoryEntry entry) {
		return new CardHistoryEntryResponse(entry.id(), entry.cardId(), entry.sessionId(),
				entry.schedulerType().getValue(), entry.schedulerGeneration(), entry.kind(),
				entry.mode(), entry.outcomeReason(), entry.comparisonVersion(), entry.usedHint(),
				entry.action(), entry.answeredAt(), entry.nextDueAt(), entry.previousBox(),
				entry.nextBox(), entry.previousEaseFactor(), entry.nextEaseFactor(),
				entry.previousIntervalDays(), entry.nextIntervalDays(), entry.direction());
	}
}
