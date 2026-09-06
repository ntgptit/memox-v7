package com.memox.deck.domain;

import com.memox.common.error.ApiErrorCode;
import com.memox.common.error.FieldValidationException;

public record DeckName(String value) {

	public static final int MAX_LENGTH = 200;

	public static DeckName of(String rawName) {
		if (rawName == null) {
			throw new FieldValidationException("name", ApiErrorCode.DECK_NAME_REQUIRED);
		}
		final var normalizedName = rawName.trim();
		if (normalizedName.isEmpty()) {
			throw new FieldValidationException("name", ApiErrorCode.DECK_NAME_REQUIRED);
		}
		if (normalizedName.length() > MAX_LENGTH) {
			throw new FieldValidationException("name", ApiErrorCode.DECK_NAME_TOO_LONG);
		}
		return new DeckName(normalizedName);
	}
}
