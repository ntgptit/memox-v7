package com.memox.trash.dto.response;

import com.memox.common.tree.DeckAncestor;

/**
 * One step of the path an item was deleted from, nearest first.
 *
 * <p>The same three fields the deck breadcrumb publishes, and deliberately a separate record. The
 * <em>entity</em> is shared vocabulary and lives in {@code common}; a response is a feature's own
 * wire shape, and borrowing another feature's would tie this endpoint's contract to changes made
 * for a deck screen. The architecture guard says exactly this, and said it here first.
 */
public record TrashOriginStepResponse(String id, String name, int distance) {

	public static TrashOriginStepResponse from(DeckAncestor ancestor) {
		return new TrashOriginStepResponse(ancestor.id(), ancestor.name(), ancestor.distance());
	}
}
