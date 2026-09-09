package com.memox.card.entity;

import java.util.List;

/**
 * One page of history, and whether there is another.
 *
 * <p>{@code hasMore} is answered by the read rather than guessed. The statement asks for one row
 * more than the page size and the extra row is dropped before returning — because inferring
 * "there is no more" from a short result cannot tell the last page from one that happens to be
 * exactly full.
 */
public record CardHistoryPage(List<CardHistoryEntry> entries, boolean hasMore) {

	public CardHistoryPage {
		entries = List.copyOf(entries);
	}
}
