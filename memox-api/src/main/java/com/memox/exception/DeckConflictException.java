package com.memox.exception;

public class DeckConflictException extends MemoxException {

	private final String code;

	public DeckConflictException(String code, String message) {
		super(message);
		this.code = code;
	}

	public String getCode() {
		return code;
	}
}
