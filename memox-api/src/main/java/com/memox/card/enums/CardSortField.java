package com.memox.card.enums;

import com.memox.common.pagination.NullOrder;
import com.memox.common.pagination.SortField;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * The orderings the card list endpoints accept.
 *
 * <p>This enum is the whitelist. A sort token that is not one of these constants is refused in the
 * transport layer, so no client-supplied string reaches the ORDER BY the mapper renders.
 *
 * <p><strong>Columns are qualified.</strong> The list statement joins {@code cards c} to
 * {@code card_study_states s}, and an unqualified {@code created_at} would be ambiguous there. Every
 * statement that uses this enum aliases its tables the same way.
 *
 * <p>{@code FRONT} orders by the folded column, which is a change from its first version. Folding
 * removes the collation disagreement translation row 8 describes for tags — PostgreSQL orders by
 * the database collation where SQLite compares bytes — and an alphabetical list that puts "apple"
 * far from "Apple" is not what the ordering is for.
 */
@Getter
@RequiredArgsConstructor
public enum CardSortField implements SortField {

	FRONT("front", "c.front_folded"),
	CREATED_AT("createdAt", "c.created_at"),
	UPDATED_AT("updatedAt", "c.updated_at"),

	/**
	 * Soonest due first — and the one ordering whose NULLs carry meaning.
	 *
	 * <p>A card with no {@code due_at} is a NEW card, due immediately, so it belongs at the front.
	 * SQLite put it there by default; PostgreSQL sorts NULLs last ascending and would bury the most
	 * urgent cards at the end of the list. The Dart source states the assumption in as many words,
	 * which is the only place it is written down.
	 */
	DUE_AT("dueAt", "s.due_at", NullOrder.FIRST);

	private final String token;
	private final String column;
	private final NullOrder nulls;

	CardSortField(String token, String column) {
		this(token, column, NullOrder.DEFAULT);
	}
}
