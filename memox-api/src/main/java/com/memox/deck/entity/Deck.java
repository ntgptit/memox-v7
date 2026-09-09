package com.memox.deck.entity;

import java.time.Instant;
import com.memox.deck.enums.DeckContentType;
import com.memox.deck.enums.SchedulerType;

public record Deck(
		String id,
		String name,
		String parentDeckId,
		String rootDeckId,
		DeckContentType contentType,
		SchedulerType schedulerType,
		Integer schedulerVersion,
		Integer schedulerGeneration,
		int siblingPosition,
		Instant createdAt,
		Instant updatedAt) {
}
