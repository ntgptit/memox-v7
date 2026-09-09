package com.memox.card.service;

import java.util.List;

/** Move a batch of cards into one deck. All of them, or none (BR-166). */
public record BulkMoveCommand(List<String> cardIds, String targetDeckId) {

	public BulkMoveCommand {
		cardIds = List.copyOf(cardIds);
	}
}
