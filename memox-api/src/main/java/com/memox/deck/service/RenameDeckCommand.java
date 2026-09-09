package com.memox.deck.service;

/** Change a deck's name. The name is trimmed before it is written. */
public record RenameDeckCommand(String deckId, String name) {
}
