package com.memox.exception;

import lombok.Getter;

@Getter
public class MemoxException extends RuntimeException {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	private final ApiErrorCode errorCode;

	protected MemoxException(ApiErrorCode errorCode) {
		super(errorCode.name());
		this.errorCode = errorCode;
	}

}
