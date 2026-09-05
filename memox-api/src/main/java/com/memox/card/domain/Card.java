package com.memox.card.domain;

import java.time.Instant;

public record Card(
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
}
