package com.memox.trash.dto.request;

import java.util.List;

import jakarta.validation.constraints.NotEmpty;

/**
 * The batches to delete permanently (BR-266).
 *
 * <p>All of one kind: a permanent delete handles cards or decks, never both. The confirmation this
 * request comes from names one kind of thing and an exact count of it.
 */
public record PurgeBatchesRequest(
		@NotEmpty(message = "{validation.required}") List<String> batchIds) {

	public PurgeBatchesRequest {
		batchIds = batchIds == null ? List.of() : List.copyOf(batchIds);
	}
}
