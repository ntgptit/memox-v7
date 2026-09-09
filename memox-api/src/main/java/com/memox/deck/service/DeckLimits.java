package com.memox.deck.service;

import lombok.experimental.UtilityClass;

/**
 * The deck tree's size limits, in one place because three callers have to agree on them.
 *
 * <p>The service enforces the depth rule, the mapper binds the walk bound, and the depth probe
 * reads the same ceiling. Three copies of "10" would drift the first time one of them changed.
 */
@UtilityClass
public class DeckLimits {

	/** BR-55: the root is level 1, and a tree may not grow past level 10. */
	public static final int MAX_TREE_DEPTH = 10;

	/**
	 * The bound every recursive ancestry walk carries.
	 *
	 * <p>One more than the deepest legal chain, so a valid tree is never truncated while corrupt
	 * cyclic data still terminates. UNION does not save these walks: {@code distance} grows on every
	 * lap, so every row stays distinct and there is nothing to deduplicate. A truncated breadcrumb
	 * is preferable to a statement that never returns.
	 */
	public static final int MAX_WALK = MAX_TREE_DEPTH + 1;
}
