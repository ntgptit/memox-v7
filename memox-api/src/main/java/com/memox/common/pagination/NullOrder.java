package com.memox.common.pagination;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * Where NULLs go in an ordering — and the reason this type exists at all.
 *
 * <p>SQLite and PostgreSQL disagree. SQLite sorts NULLs FIRST ascending; PostgreSQL sorts them
 * LAST. Every ported ORDER BY over a nullable column therefore changes meaning unless the
 * difference is stated, and it changes it silently: the rows are all still there, in an order that
 * looks plausible.
 *
 * <p>The case that made this necessary is {@code card_study_states.due_at}. A null due date means a
 * new card, due now, so "soonest due first" must put those at the FRONT. SQLite did that by
 * accident of its collation and the Dart source says so in as many words. PostgreSQL would put them
 * last — turning the most urgent cards into the tail of the list.
 *
 * <p>{@link #DEFAULT} renders nothing, so a column whose NULL placement does not matter produces
 * exactly the SQL it did before this type existed.
 */
@Getter
@RequiredArgsConstructor
public enum NullOrder {

	DEFAULT(""),
	FIRST(" NULLS FIRST"),
	LAST(" NULLS LAST");

	/** Rendered straight into ORDER BY, which is safe because these three strings are the only ones. */
	private final String sql;
}
