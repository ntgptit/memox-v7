package com.memox.card.entity;

/**
 * The duplicate identity BR-170 measures import against: the two folded faces.
 *
 * <p>A typed pair rather than a joined string, following AD-20: every separator scheme rests on the
 * unspoken invariant that the separator does not occur in the text, and no type defends it.
 * Structural equality has no separator to get wrong.
 */
public record CardKey(String frontFolded, String backFolded) {
}
