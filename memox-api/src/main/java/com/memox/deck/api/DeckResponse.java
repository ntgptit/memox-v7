package com.memox.deck.api;

import java.time.Instant;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.memox.deck.domain.Deck;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record DeckResponse(
		String id,
		String name,
		String parentDeckId,
		String rootDeckId,
		String contentType,
		String schedulerType,
		Integer schedulerVersion,
		Integer schedulerGeneration,
		int siblingPosition,
		Instant createdAt,
		Instant updatedAt) {

	static DeckResponse from(Deck deck) {
		return new DeckResponse(deck.id(), deck.name(), deck.parentDeckId(), deck.rootDeckId(),
				deck.contentType(), deck.schedulerType(), deck.schedulerVersion(),
				deck.schedulerGeneration(), deck.siblingPosition(), deck.createdAt(), deck.updatedAt());
	}
}
