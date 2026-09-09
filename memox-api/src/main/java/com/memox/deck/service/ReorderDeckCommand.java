package com.memox.deck.service;

/**
 * Move one deck to a new place among its siblings.
 *
 * <p>The sibling group is derived from the deck itself rather than named by the caller. A parent id
 * in the command would be a second source of truth for the same fact, and the two could disagree.
 *
 * @param targetPosition the zero-based index within the ACTIVE siblings, which is what the user
 *                       sees — not the raw {@code sibling_position} column, which tombstones share
 */
public record ReorderDeckCommand(String deckId, int targetPosition) {
}
