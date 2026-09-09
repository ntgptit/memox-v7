package com.memox.deck.exception;

import com.memox.common.error.ApiErrorCode;
import com.memox.common.error.MemoxException;

import lombok.Getter;

/**
 * A deck id that resolved to nothing active.
 *
 * <p>The id is kept, not merely accepted. It reaches the log through the exception message, which
 * is what makes a production 404 investigable: before this, the exception carried the string
 * "DECK_NOT_FOUND" and nothing else, so the id that was not found could not be recovered from the
 * log line.
 *
 * <p>Nothing is <strong>added</strong> to the {@code ProblemDetail} for it. The body says which
 * rule refused the request; the id is diagnostic and belongs in the log. Spring's standard
 * {@code instance} field does echo the request URI, and on a path-variable endpoint the id is part
 * of that URI — which is the client's own input coming back, not a disclosure this class makes.
 */
@Getter
public class DeckNotFoundException extends MemoxException {

	private static final long serialVersionUID = -7648723892456827919L;

	private final String deckId;

	public DeckNotFoundException(String deckId) {
		super(ApiErrorCode.DECK_NOT_FOUND, "deckId=" + deckId);
		this.deckId = deckId;
	}
}
