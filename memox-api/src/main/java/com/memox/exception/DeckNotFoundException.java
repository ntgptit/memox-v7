package com.memox.exception;

public class DeckNotFoundException extends MemoxException {

	public DeckNotFoundException(String deckId) {
		super(ApiErrorCode.DECK_NOT_FOUND);
	}
}
