package com.memox.card.domain;

import com.memox.common.error.ApiErrorCode;
import com.memox.common.error.FieldValidationException;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum CardTextField {

	FRONT("front", 60),
	BACK("back", 240),
	EXAMPLE("example", 240),
	HINT("hint", 240),
	PRONUNCIATION("pronunciation", 240);

	private final String fieldName;
	private final int maxLength;

	public String normalizeRequired(String rawText) {
		if (rawText == null) {
			throw new FieldValidationException(fieldName, requiredCode());
		}
		final var normalizedText = rawText.trim();
		if (normalizedText.isEmpty()) {
			throw new FieldValidationException(fieldName, requiredCode());
		}
		return validateMaximumLength(normalizedText);
	}

	public String normalizeOptional(String rawText) {
		if (rawText == null) {
			return null;
		}
		final var normalizedText = rawText.trim();
		if (normalizedText.isEmpty()) {
			return null;
		}
		return validateMaximumLength(normalizedText);
	}

	private String validateMaximumLength(String text) {
		if (text.length() > maxLength) {
			throw new FieldValidationException(fieldName, tooLongCode());
		}
		return text;
	}

	private ApiErrorCode requiredCode() {
		return switch (this) {
			case FRONT -> ApiErrorCode.CARD_FRONT_REQUIRED;
			case BACK -> ApiErrorCode.CARD_BACK_REQUIRED;
			case EXAMPLE, HINT, PRONUNCIATION -> throw new IllegalStateException(
					"Optional card fields cannot require a value.");
		};
	}

	private ApiErrorCode tooLongCode() {
		return switch (this) {
			case FRONT -> ApiErrorCode.CARD_FRONT_TOO_LONG;
			case BACK -> ApiErrorCode.CARD_BACK_TOO_LONG;
			case EXAMPLE -> ApiErrorCode.CARD_EXAMPLE_TOO_LONG;
			case HINT -> ApiErrorCode.CARD_HINT_TOO_LONG;
			case PRONUNCIATION -> ApiErrorCode.CARD_PRONUNCIATION_TOO_LONG;
		};
	}
}
