package com.memox.common.error;

import lombok.Getter;

/**
 * The base for every failure this API turns into a Problem Details response.
 *
 * <p>The message is diagnostic and goes to the log; the {@link ApiErrorCode} is what the client
 * sees. They are deliberately different audiences, and the split is what lets the message name the
 * row that failed without that identifier being echoed back over HTTP.
 *
 * <p><strong>The detail carries identifiers, counts and codes. Never content.</strong> A deck id is
 * a lookup key the caller already holds; a deck name, a card face, a note or a tag name is user
 * material that BR-51, BR-52 and BR-267 forbid at every log level. The Checkstyle rule
 * {@code noPrivateContentInLogs} watches both the logging calls and these constructors, so the
 * boundary is enforced rather than remembered.
 */
@Getter
public class MemoxException extends RuntimeException {

	private static final long serialVersionUID = 1L;

	private final ApiErrorCode errorCode;

	protected MemoxException(ApiErrorCode errorCode) {
		super(errorCode.name());
		this.errorCode = errorCode;
	}

	/**
	 * @param detail identifiers, counts or codes explaining which row or rule failed — never content
	 */
	protected MemoxException(ApiErrorCode errorCode, String detail) {
		super(errorCode.name() + ": " + detail);
		this.errorCode = errorCode;
	}
}
