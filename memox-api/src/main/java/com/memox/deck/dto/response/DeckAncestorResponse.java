package com.memox.deck.dto.response;

import com.memox.deck.entity.DeckAncestor;

/**
 * One crumb of the breadcrumb.
 *
 * @param distance 1 for the immediate parent, growing towards the root — carried rather than
 *                 implied by list position, because position is not a guarantee the API makes
 */
public record DeckAncestorResponse(String id, String name, int distance) {

	public static DeckAncestorResponse from(DeckAncestor ancestor) {
		return new DeckAncestorResponse(ancestor.id(), ancestor.name(), ancestor.distance());
	}
}
