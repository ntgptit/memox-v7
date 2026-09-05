package com.memox.card.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record CreateCardRequest(
		@NotBlank @Pattern(regexp = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$") String id,
		@NotBlank @Size(max = 60) String front,
		@NotBlank @Size(max = 240) String back,
		@Size(max = 240) String example,
		@Size(max = 240) String hint,
		@Size(max = 240) String pronunciation) {
}
