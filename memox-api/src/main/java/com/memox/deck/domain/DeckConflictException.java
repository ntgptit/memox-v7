package com.memox.deck.domain;

import com.memox.common.error.ApiErrorCode;
import com.memox.common.error.MemoxException;

public class DeckConflictException extends MemoxException {

	/**
	 *
	 */
	private static final long serialVersionUID = 1454917966445674259L;

	public DeckConflictException(ApiErrorCode errorCode) {
		super(errorCode);
	}
}
