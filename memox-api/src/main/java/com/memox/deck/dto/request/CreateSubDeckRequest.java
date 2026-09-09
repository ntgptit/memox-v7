package com.memox.deck.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import com.memox.common.validation.ValidationPatterns;

public record CreateSubDeckRequest(
		@NotBlank(message = "{validation.required}")
		@Pattern(regexp = ValidationPatterns.UUID, message = "{validation.uuid}") String id,
		@NotBlank(message = "{validation.required}") @Size(max = ValidationPatterns.DECK_NAME_MAX_LENGTH, message = "{validation.max-length}") String name) {
}
