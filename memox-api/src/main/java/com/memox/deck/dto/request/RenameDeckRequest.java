package com.memox.deck.dto.request;

import com.memox.common.validation.ValidationPatterns;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** The new name. It is trimmed before it is written, so surrounding space is not a rejection. */
public record RenameDeckRequest(
		@NotBlank(message = "{validation.required}")
		@Size(max = ValidationPatterns.DECK_NAME_MAX_LENGTH, message = "{validation.max-length}")
		String name) {
}
