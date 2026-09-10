package com.memox.tag.dto.request;

import java.util.List;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

/** Attach one tag, named by its text, to a batch of cards (BR-166). */
public record AttachTagRequest(
		@NotEmpty(message = "{validation.required}") List<String> cardIds,
		@NotNull(message = "{validation.required}") String name) {

	public AttachTagRequest {
		cardIds = cardIds == null ? List.of() : List.copyOf(cardIds);
	}
}
