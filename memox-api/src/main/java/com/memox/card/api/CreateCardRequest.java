package com.memox.card.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record CreateCardRequest(
		@NotBlank(message = "{validation.required}")
		@Pattern(regexp = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$", message = "{validation.uuid}") String id,
		@NotBlank(message = "{validation.required}") @Size(max = 60, message = "{validation.max-length}") String front,
		@NotBlank(message = "{validation.required}") @Size(max = 240, message = "{validation.max-length}") String back,
		@Size(max = 240, message = "{validation.max-length}") String example,
		@Size(max = 240, message = "{validation.max-length}") String hint,
		@Size(max = 240, message = "{validation.max-length}") String pronunciation) {
}
