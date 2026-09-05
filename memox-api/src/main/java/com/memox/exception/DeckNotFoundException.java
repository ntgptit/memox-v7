package com.memox.exception;

public class DeckNotFoundException extends MemoxException {

	public DeckNotFoundException(String deckId) {
		super("Deck %s does not exist.".formatted(deckId));
	}
}
