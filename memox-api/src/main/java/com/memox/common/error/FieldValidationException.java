package com.memox.common.error;

import lombok.Getter;

@Getter
public class FieldValidationException extends MemoxException {

	private final String field;

	public FieldValidationException(String field, ApiErrorCode errorCode) {
		super(errorCode);
		this.field = field;
	}
}
