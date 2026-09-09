package com.memox.card.dto.response;

import java.time.Instant;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.memox.card.entity.Card;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record CardResponse(
		String id,
		String deckId,
		String front,
		String back,
		boolean flagged,
		String example,
		String hint,
		String pronunciation,
		Instant createdAt,
		Instant updatedAt) {

	public static CardResponse from(Card card) {
		return new CardResponse(card.id(), card.deckId(), card.front(), card.back(), card.flagged(),
				card.example(), card.hint(), card.pronunciation(), card.createdAt(), card.updatedAt());
	}
}
