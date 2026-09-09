package com.memox.common.pagination;

/**
 * A sort already resolved to the terms SQL speaks: a real column name, a direction, and where NULLs
 * go.
 *
 * <p>This is the only sort shape the persistence layer sees. All three parts originate in code —
 * the column from a {@link SortField} constant, the direction and the null placement from enum
 * constants — which is what makes rendering them with MyBatis's substituting {@code $} syntax safe.
 * Construct one from a client-supplied string and that property is gone.
 *
 * <p>The two-argument form means {@link NullOrder#DEFAULT}: let the database decide, which is right
 * for a NOT NULL column and for any ordering where the placement carries no meaning.
 */
public record SortColumn(String column, SortDirection direction, NullOrder nulls) {

	public SortColumn(String column, SortDirection direction) {
		this(column, direction, NullOrder.DEFAULT);
	}
}
