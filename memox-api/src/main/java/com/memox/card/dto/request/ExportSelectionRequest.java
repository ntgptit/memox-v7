package com.memox.card.dto.request;

import java.util.List;

import jakarta.validation.constraints.NotEmpty;

/**
 * The ids of scope {@code selected} (BR-174).
 *
 * <p>An empty selection is refused here rather than treated as "everything": BR-174 says an empty
 * scope must be refused in the repository even when the UI has hidden the action, and a request
 * that omitted the field did not mean "export the whole deck".
 */
public record ExportSelectionRequest(
		@NotEmpty(message = "{validation.required}") List<String> cardIds) {

	public ExportSelectionRequest {
		cardIds = cardIds == null ? List.of() : List.copyOf(cardIds);
	}
}
