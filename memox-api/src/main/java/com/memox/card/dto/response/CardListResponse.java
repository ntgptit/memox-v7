package com.memox.card.dto.response;

import java.time.Instant;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.memox.card.entity.CardListItem;

/** One row of the management list: the card, its schedule and its tag names. */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record CardListResponse(
		String id,
		String deckId,
		String front,
		String back,
		boolean flagged,
		String example,
		String hint,
		String pronunciation,
		Instant createdAt,
		Instant updatedAt,
		String schedulerType,
		int schedulerGeneration,
		Instant learnedAt,
		Instant dueAt,
		Instant lastAnsweredAt,
		int answerCount,
		int lapseCount,
		Integer currentBox,
		Double easeFactor,
		Integer intervalDays,
		Integer repetitions,
		List<String> tagNames) {

	public CardListResponse {
		tagNames = List.copyOf(tagNames);
	}

	public static CardListResponse from(CardListItem item) {
		return new CardListResponse(item.id(), item.deckId(), item.front(), item.back(),
				item.flagged(), item.example(), item.hint(), item.pronunciation(),
				item.createdAt(), item.updatedAt(), item.schedulerType().getValue(),
				item.schedulerGeneration(), item.learnedAt(), item.dueAt(), item.lastAnsweredAt(),
				item.answerCount(), item.lapseCount(), item.currentBox(), item.easeFactor(),
				item.intervalDays(), item.repetitions(), item.tagNames());
	}
}
