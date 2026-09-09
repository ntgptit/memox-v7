package com.memox.deck.service;

/** Move one deck, and everything under it, beneath another deck. */
public record MoveDeckCommand(String deckId, String targetParentDeckId) {
}
