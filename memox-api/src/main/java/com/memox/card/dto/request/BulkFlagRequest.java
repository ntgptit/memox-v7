package com.memox.card.dto.request;

import java.util.List;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

/**
 * Set the flag on a batch of cards.
 *
 * <p>{@code flagged} is required rather than defaulted: a request that omitted it would be read as
 * "unflag everything", which is not what a client that forgot the field meant.
 */
public record BulkFlagRequest(
		@NotEmpty(message = "{validation.required}") List<String> cardIds,
		@NotNull(message = "{validation.required}") Boolean flagged) {

	public BulkFlagRequest {
		cardIds = cardIds == null ? List.of() : List.copyOf(cardIds);
	}
}
