package com.memox.card.application;

public record CreateCardCommand(
		String id,
		String deckId,
		String front,
		String back,
		String example,
		String hint,
		String pronunciation) {
}
