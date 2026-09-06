package com.memox.exception;

import lombok.Getter;

@Getter
public class DeckValidationException extends MemoxException {

	private final String field;

	public DeckValidationException(String field, ApiErrorCode errorCode) {
		super(errorCode);
		this.field = field;
	}
}
