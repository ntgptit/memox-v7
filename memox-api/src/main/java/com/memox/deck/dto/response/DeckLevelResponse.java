package com.memox.deck.dto.response;

import java.time.Instant;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.memox.deck.entity.DeckLevel;

/**
 * One deck opened, in one response: header, breadcrumb, children and the screen's re-measure moment.
 *
 * <p>{@code nextDueAt} sits beside {@code children} rather than inside each of them, because it is
 * one fact about this view: the earliest instant at which any count on it would change. A per-child
 * value would say something the statement does not measure.
 *
 * @param nextDueAt absent when nothing in this level's subtrees is scheduled to become due
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record DeckLevelResponse(
		DeckContextResponse parent,
		List<DeckLevelChildResponse> children,
		Instant nextDueAt) {

	public DeckLevelResponse {
		children = List.copyOf(children);
	}

	public static DeckLevelResponse from(DeckLevel level) {
		return new DeckLevelResponse(DeckContextResponse.from(level.parent()),
				level.children().stream().map(DeckLevelChildResponse::from).toList(),
				level.nextDueAt());
	}
}
