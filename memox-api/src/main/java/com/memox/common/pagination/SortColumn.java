package com.memox.common.pagination;

/**
 * A sort already resolved to the terms SQL speaks: a real column name and a direction keyword.
 *
 * <p>This is the only sort shape the persistence layer sees. Both halves originate in code — the
 * column from a {@link SortField} constant, the direction from a {@link SortDirection} constant —
 * which is what makes rendering them with MyBatis's substituting {@code $} syntax safe. Construct
 * one from a client-supplied string and that property is gone.
 */
public record SortColumn(String column, SortDirection direction) {
}
