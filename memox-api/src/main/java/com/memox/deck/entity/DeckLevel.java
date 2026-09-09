package com.memox.deck.entity;

import java.time.Instant;
import java.util.List;

/**
 * One deck opened: its header, its direct children with their subtree counts, and when the screen
 * should look again.
 *
 * <p>All of it from one statement. A screen that needs the title and the breadcrumb at once must
 * get them from one read, or it can render a name from before a rename and a path from after it
 * (AD-13).
 *
 * <p><strong>{@code nextDueAt} belongs to the level, not to a child.</strong> It is the earliest
 * instant at which any count on this screen would change, and the screen schedules its re-measure
 * from it — one timer for the view, scoped to the subtrees this level actually shows. A card
 * scheduled in an unrelated tree does not move a number here, so it must not wake the screen
 * either. The Phase 2 plan told this task to restrict the scalar to each child; that is the same
 * per-row mistake PR #517 reverted one level up, and the plan has been corrected.
 *
 * @param parent the opened deck and the path above it
 * @param children direct children only, in sibling order
 * @param nextDueAt null when nothing in this level's subtrees is scheduled to become due — a real
 *                  state, and one the screen must not set a timer for
 */
public record DeckLevel(DeckContext parent, List<DeckLevelChild> children, Instant nextDueAt) {

	public DeckLevel {
		children = List.copyOf(children);
	}
}
