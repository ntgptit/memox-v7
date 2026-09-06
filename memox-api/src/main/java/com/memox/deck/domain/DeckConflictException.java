package com.memox.deck.domain;

import com.memox.common.error.ApiErrorCode;
import com.memox.common.error.MemoxException;

public class DeckConflictException extends MemoxException {

	public DeckConflictException(ApiErrorCode errorCode) {
		super(errorCode);
	}
}
