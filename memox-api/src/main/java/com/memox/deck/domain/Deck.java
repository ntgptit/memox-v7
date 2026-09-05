package com.memox.deck.domain;

import java.time.Instant;

public record Deck(
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
}
