package com.memox.deck.exception;

import com.memox.common.error.ApiErrorCode;
import com.memox.common.error.MemoxException;

import lombok.Getter;

/**
 * A deck rule that refused the write, together with the deck it refused it on.
 *
 * <p>Same reasoning as {@link DeckNotFoundException}: the id is diagnostic, so it belongs in the
 * message the handler logs and not in the response body. Depth, content-type and scheduler
 * conflicts all arrive here, and "which deck" is the first question asked about any of them.
 */
@Getter
public class DeckConflictException extends MemoxException {

	private static final long serialVersionUID = 1454917966445674259L;

	private final String deckId;

	public DeckConflictException(ApiErrorCode errorCode, String deckId) {
		super(errorCode, "deckId=" + deckId);
		this.deckId = deckId;
	}
}
