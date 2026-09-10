package com.memox.deck.entity;

import com.memox.common.tree.DeckAncestor;

import java.util.List;

import com.memox.deck.enums.DeckContentType;

/**
 * A deck's own identity plus the path of ancestors above it — the header of any screen opened on it.
 *
 * <p>One shape for two statements. The card list header reads it directly, and the level view
 * carries it as its parent, so a rename of an ancestor moves the title and the breadcrumb together
 * or moves neither (AD-13).
 *
 * <p>The deck itself is deliberately absent from {@code ancestry}: it is {@link #deckName()} here,
 * and putting it in both would let the title and the last crumb disagree.
 */
public record DeckContext(
		String deckId,
		String deckName,
		DeckContentType contentType,
		List<DeckAncestor> ancestry) {

	public DeckContext {
		ancestry = List.copyOf(ancestry);
	}
}
