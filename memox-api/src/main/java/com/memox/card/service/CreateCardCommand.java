package com.memox.card.service;

public record CreateCardCommand(
		String id,
		String deckId,
		String front,
		String back,
		String example,
		String hint,
		String pronunciation) {
}
