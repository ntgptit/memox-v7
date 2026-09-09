package com.memox.card.entity;

/**
 * Where one card currently lives, with the facts a bulk move has to check.
 *
 * <p>Read for the whole batch in one statement rather than per card: a bulk move validates every
 * card against the same target, and a lookup per card would be N round trips inside the write
 * transaction.
 *
 * <p>The plan also specified the deck's {@code parentDeckId} and {@code contentType} here. Nothing
 * reads them — those are properties of the TARGET, which the move validates from the locked
 * {@code Deck} the deck module hands it. Carrying them would put a deck's own vocabulary inside a
 * card record for no caller, which is what the architecture guard objected to.
 */
public record CardDeckContext(String cardId, String deckId, String rootDeckId) {
}
