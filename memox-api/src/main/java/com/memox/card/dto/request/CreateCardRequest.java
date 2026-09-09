package com.memox.card.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import com.memox.common.validation.ValidationPatterns;

public record CreateCardRequest(
		@NotBlank(message = "{validation.required}")
		@Pattern(regexp = ValidationPatterns.UUID, message = "{validation.uuid}") String id,
		@NotBlank(message = "{validation.required}") @Size(max = 60, message = "{validation.max-length}") String front,
		@NotBlank(message = "{validation.required}") @Size(max = 240, message = "{validation.max-length}") String back,
		@Size(max = 240, message = "{validation.max-length}") String example,
		@Size(max = 240, message = "{validation.max-length}") String hint,
		@Size(max = 240, message = "{validation.max-length}") String pronunciation) {
}
