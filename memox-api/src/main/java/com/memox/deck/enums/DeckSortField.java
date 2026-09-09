package com.memox.deck.enums;

import com.memox.common.pagination.SortField;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * The orderings the deck list endpoint accepts.
 *
 * <p>This enum is the whitelist. A sort token that is not one of these constants is refused in the
 * transport layer, so no client-supplied string ever reaches the ORDER BY clause the mapper
 * renders. Widening the list is a deliberate one-line change here, not a client's choice.
 *
 * <p>{@code id} is absent on purpose: it is the tie-breaker every deck page carries anyway, and
 * offering it as a sort would publish an ordering with no meaning to a user.
 */
@Getter
@RequiredArgsConstructor
public enum DeckSortField implements SortField {

	SIBLING_POSITION("siblingPosition", "sibling_position"),
	NAME("name", "name"),
	CREATED_AT("createdAt", "created_at"),
	UPDATED_AT("updatedAt", "updated_at");

	private final String token;
	private final String column;
}
