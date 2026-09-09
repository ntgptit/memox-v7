package com.memox.card.entity;

import java.util.List;

/**
 * Which cards a list is asking for. Orthogonal to the ordering, so every filter works with every
 * sort and neither needs a query per pair.
 *
 * @param flagged a boxed {@code Boolean} on purpose: {@code null} means "do not filter on the flag
 *                at all", which a primitive cannot express — and "unflagged only" is a real request
 *                that {@code false} has to keep meaning
 * @param tagIds OR-semantics (BR-231): a card matches if it carries ANY of them, and it appears
 *               once however many it carries (BR-252)
 * @param searchFolded already folded by the caller — the same {@code trim().toLowerCase()} the
 *                     folded columns were written with, so the comparison is like for like
 */
public record CardFilter(
		String deckId,
		boolean includeSubtree,
		Boolean flagged,
		List<String> tagIds,
		String searchFolded) {

	public CardFilter {
		tagIds = List.copyOf(tagIds);
	}

	public static CardFilter ofDeck(String deckId) {
		return new CardFilter(deckId, false, null, List.of(), null);
	}

	public CardFilter includingSubtree() {
		return new CardFilter(deckId, true, flagged, tagIds, searchFolded);
	}

	public CardFilter withFlagged(Boolean wanted) {
		return new CardFilter(deckId, includeSubtree, wanted, tagIds, searchFolded);
	}

	public CardFilter withTagIds(List<String> wanted) {
		return new CardFilter(deckId, includeSubtree, flagged, wanted, searchFolded);
	}

	public CardFilter searchingFor(String folded) {
		return new CardFilter(deckId, includeSubtree, flagged, tagIds, folded);
	}

	/**
	 * Whether the tag filter is active.
	 *
	 * <p>Asked rather than left to the statement, because an empty {@code IN ()} list is a syntax
	 * error in PostgreSQL — translation row 9. An empty list means "no tag filter", not "match
	 * nothing".
	 */
	public boolean hasTagFilter() {
		return !tagIds.isEmpty();
	}
}
