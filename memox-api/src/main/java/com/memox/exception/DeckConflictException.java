package com.memox.exception;

public class DeckConflictException extends MemoxException {

	public DeckConflictException(ApiErrorCode errorCode) {
		super(errorCode);
	}
}
