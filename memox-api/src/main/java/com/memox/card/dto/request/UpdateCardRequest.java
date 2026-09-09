package com.memox.card.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * New content for a card. Content only — the flag and the schedule are not editable here (BR-92).
 */
public record UpdateCardRequest(
		@NotBlank(message = "{validation.required}")
		@Size(max = 240, message = "{validation.max-length}") String front,
		@NotBlank(message = "{validation.required}")
		@Size(max = 240, message = "{validation.max-length}") String back,
		String example,
		String hint,
		String pronunciation) {
}
