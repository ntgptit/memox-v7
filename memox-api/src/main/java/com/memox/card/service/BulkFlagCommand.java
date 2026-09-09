package com.memox.card.service;

import java.util.List;

/**
 * Set the flag on a batch of cards.
 *
 * <p>Set, not toggle. A toggle derived from the first card leaves a mixed selection mixed, and the
 * user asked for one state.
 */
public record BulkFlagCommand(List<String> cardIds, boolean flagged) {

	public BulkFlagCommand {
		cardIds = List.copyOf(cardIds);
	}
}
