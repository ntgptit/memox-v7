package com.memox.trash.service;

import java.util.List;

/**
 * Move a batch of cards to Trash — one batch per card (BR-256).
 *
 * <p>A one-card delete is a one-element list, deliberately: a second write path would be a second
 * place for the emptied-deck rule to be forgotten.
 */
public record DeleteCardsCommand(List<String> cardIds) {

	public DeleteCardsCommand {
		cardIds = cardIds == null ? List.of() : List.copyOf(cardIds);
	}
}
