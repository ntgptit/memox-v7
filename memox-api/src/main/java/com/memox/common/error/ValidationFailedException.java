package com.memox.common.error;

import lombok.Getter;

/**
 * A request parameter this API could not accept, named together with the reason.
 *
 * <p>Bean Validation covers the parameters a constraint annotation can describe. This covers the
 * ones it cannot — a sort token that has to resolve against a feature's enum, for example — and it
 * carries the same two pieces of information, so both paths reach the client as one
 * {@code fieldErrors} shape rather than two.
 *
 * <p>{@code reason} is written for the client and must stay free of user content: it explains what
 * the endpoint accepts, and never repeats what arrived.
 */
@Getter
public class ValidationFailedException extends MemoxException {

	private static final long serialVersionUID = 2735419855121213003L;

	private final String field;
	private final String reason;

	public ValidationFailedException(String field, String reason) {
		super(ApiErrorCode.VALIDATION_FAILED, field + ": " + reason);
		this.field = field;
		this.reason = reason;
	}
}
