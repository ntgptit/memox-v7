package com.memox.card.exception;

import com.memox.common.error.ApiErrorCode;
import com.memox.common.error.MemoxException;

import lombok.Getter;

/**
 * A card id that resolved to nothing active.
 *
 * <p>A card in Trash produces this too (BR-245, BR-257): on every active surface a tombstoned card
 * must read as not-found rather than showing its content.
 *
 * <p>The id is carried into the message, which the exception handler logs, and is not added to the
 * response body — the same split DeckNotFoundException makes.
 */
@Getter
public class CardNotFoundException extends MemoxException {

	private static final long serialVersionUID = 8801525364423178215L;

	private final String cardId;

	public CardNotFoundException(String cardId) {
		super(ApiErrorCode.CARD_NOT_FOUND, "cardId=" + cardId);
		this.cardId = cardId;
	}
}
