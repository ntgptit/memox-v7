package com.memox.card.enums;

import com.memox.common.pagination.SortField;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * The orderings the card list endpoint accepts.
 *
 * <p>Same whitelist contract as {@code DeckSortField}: these constants are the only columns a
 * client can order by, and the token/column split keeps the database name off the wire.
 *
 * <p>{@code front} orders by the stored face, not by the folded search column. The folded column
 * exists for matching, and sorting by it would order "Apple" and "apple" identically while
 * displaying them as different rows.
 */
@Getter
@RequiredArgsConstructor
public enum CardSortField implements SortField {

	FRONT("front", "front"),
	CREATED_AT("createdAt", "created_at"),
	UPDATED_AT("updatedAt", "updated_at");

	private final String token;
	private final String column;
}
