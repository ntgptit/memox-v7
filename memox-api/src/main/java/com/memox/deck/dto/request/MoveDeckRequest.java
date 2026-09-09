package com.memox.deck.dto.request;

import com.memox.common.validation.ValidationPatterns;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/** Where the deck should go. The deck being moved is the path variable. */
public record MoveDeckRequest(
		@NotBlank(message = "{validation.required}")
		@Pattern(regexp = ValidationPatterns.UUID, message = "{validation.uuid}")
		String targetParentDeckId) {
}
