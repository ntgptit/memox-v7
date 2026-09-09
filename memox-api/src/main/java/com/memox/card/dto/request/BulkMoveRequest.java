package com.memox.card.dto.request;

import java.util.List;

import com.memox.common.validation.ValidationPatterns;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;

/** Move a batch of cards into one deck. All of them, or none. */
public record BulkMoveRequest(
		@NotEmpty(message = "{validation.required}") List<String> cardIds,
		@NotBlank(message = "{validation.required}")
		@Pattern(regexp = ValidationPatterns.UUID, message = "{validation.uuid}")
		String targetDeckId) {

	public BulkMoveRequest {
		cardIds = cardIds == null ? List.of() : List.copyOf(cardIds);
	}
}
