package com.memox.card.dto.request;

import java.util.List;
import java.util.Locale;

import com.memox.card.entity.CardFilter;

/**
 * The filter half of the card list query string. The paging half is {@code CardPageRequest}.
 *
 * @param includeSubtree null means false — a deck's own cards only
 * @param flagged null means do not filter on the flag; true and false are both real requests
 * @param tagIds OR-semantics: a card matches if it carries any of them
 * @param q free text, folded here rather than by the caller so the comparison matches the folded
 *          columns exactly
 */
public record CardFilterRequest(
		String deckId,
		Boolean includeSubtree,
		Boolean flagged,
		List<String> tagIds,
		String q) {

	public CardFilterRequest {
		tagIds = tagIds == null ? List.of() : List.copyOf(tagIds);
	}

	public CardFilter toFilter() {
		return new CardFilter(deckId, Boolean.TRUE.equals(includeSubtree), flagged, tagIds, fold(q));
	}

	/** The same fold the folded columns were written with: {@code raw.trim().toLowerCase()}. */
	private static String fold(String raw) {
		if (raw == null || raw.isBlank()) {
			return null;
		}
		return raw.trim().toLowerCase(Locale.ROOT);
	}
}
