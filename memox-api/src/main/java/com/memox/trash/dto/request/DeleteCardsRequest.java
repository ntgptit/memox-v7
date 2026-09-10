package com.memox.trash.dto.request;

import java.util.List;

import jakarta.validation.constraints.NotEmpty;

/** The cards to move to Trash. One batch is opened per id (BR-256). */
public record DeleteCardsRequest(
		@NotEmpty(message = "{validation.required}") List<String> cardIds) {

	public DeleteCardsRequest {
		cardIds = cardIds == null ? List.of() : List.copyOf(cardIds);
	}
}
