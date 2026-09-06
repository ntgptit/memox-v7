package com.memox.deck.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import com.memox.common.validation.ValidationPatterns;

public record CreateSubDeckRequest(
		@NotBlank(message = "{validation.required}")
		@Pattern(regexp = ValidationPatterns.UUID, message = "{validation.uuid}") String id,
		@NotBlank(message = "{validation.required}") @Size(max = 200, message = "{validation.max-length}") String name) {
}
