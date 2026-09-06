package com.memox.deck.domain;

import com.memox.common.error.ApiErrorCode;
import com.memox.common.error.MemoxException;

public class DeckNotFoundException extends MemoxException {

	/**
	 *
	 */
	private static final long serialVersionUID = -7648723892456827919L;

	public DeckNotFoundException(String deckId) {
		super(ApiErrorCode.DECK_NOT_FOUND);
	}
}
