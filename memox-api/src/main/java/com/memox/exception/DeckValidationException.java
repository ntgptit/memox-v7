package com.memox.exception;

public class DeckValidationException extends MemoxException {

	private final String field;
	private final String code;

	public DeckValidationException(String field, String code, String message) {
		super(message);
		this.field = field;
		this.code = code;
	}

	public String getField() {
		return field;
	}

	public String getCode() {
		return code;
	}
}
