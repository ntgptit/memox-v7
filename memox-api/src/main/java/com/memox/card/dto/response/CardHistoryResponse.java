package com.memox.card.dto.response;

import java.util.List;

import com.memox.card.entity.CardHistoryPage;

/**
 * One page of review history, newest first, with the cursor for the next page.
 *
 * <p>{@code hasMore} is read, not inferred: the statement fetches one row beyond the page so a full
 * last page is distinguishable from a page with more behind it. The cursor is the last returned
 * row, and the next page starts strictly after it.
 */
public record CardHistoryResponse(
		List<CardHistoryEntryResponse> entries,
		boolean hasMore,
		CardHistoryCursorResponse nextCursor) {

	public CardHistoryResponse {
		entries = List.copyOf(entries);
	}

	public static CardHistoryResponse from(CardHistoryPage page) {
		final var entries = page.entries().stream().map(CardHistoryEntryResponse::from).toList();
		return new CardHistoryResponse(entries, page.hasMore(), nextCursor(page));
	}

	private static CardHistoryCursorResponse nextCursor(CardHistoryPage page) {
		if (!page.hasMore() || page.entries().isEmpty()) {
			return null;
		}
		final var last = page.entries().get(page.entries().size() - 1);
		return new CardHistoryCursorResponse(last.answeredAt(), last.id());
	}
}
