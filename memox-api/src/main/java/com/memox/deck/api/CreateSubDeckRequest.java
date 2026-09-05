package com.memox.deck.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record CreateSubDeckRequest(
		@NotBlank(message = "{validation.required}")
		@Pattern(regexp = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$", message = "{validation.uuid}") String id,
		@NotBlank(message = "{validation.required}") @Size(max = 200, message = "{validation.max-length}") String name) {
}
