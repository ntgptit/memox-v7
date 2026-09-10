package com.memox.common.tree;

/**
 * One step of the path back up to the root, as the breadcrumb shows it.
 *
 * <p>{@code distance} rides inside each entry rather than being implied by list position, because
 * SQL does not promise aggregate input order. The statement sorts by it and so can the reader —
 * position alone would be a guarantee nobody made.
 *
 * @param distance 1 for the immediate parent, growing towards the root
 */
public record DeckAncestor(String id, String name, int distance) {
}
