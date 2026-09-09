package com.memox.deck.entity;

import com.memox.deck.enums.DeckContentType;

/**
 * A deck a card may be moved into, with enough context to tell two same-named decks apart.
 *
 * <p>{@code parentName} is why this is not just a {@link Deck}: the picker shows a flat list, and
 * two lessons both called "Unit 1" under different units are indistinguishable without it.
 */
public record DeckMoveTarget(
		String deckId,
		String deckName,
		DeckContentType contentType,
		String parentName) {
}
