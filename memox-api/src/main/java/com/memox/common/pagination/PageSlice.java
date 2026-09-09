package com.memox.common.pagination;

import java.util.List;

/**
 * The slice of rows one page asks for, expressed the way SQL takes it.
 *
 * <p>{@link PageQuery} is the request; this is its translation. The API counts in pages and the
 * database counts in rows, and the conversion happens once, here, rather than in every statement.
 *
 * <p>{@code sorts} is never empty. The mapper XML renders {@code ORDER BY} straight from this list,
 * so an empty one would produce {@code ORDER BY LIMIT ...} — a syntax error found at run time
 * against a real database. The constructor refuses it instead, which turns that into a failure at
 * the point the mistake is made.
 */
public record PageSlice(int limit, long offset, List<SortColumn> sorts) {

	public PageSlice {
		if (sorts.isEmpty()) {
			throw new IllegalArgumentException(
					"a page slice needs at least one sort; ORDER BY cannot be empty");
		}
		sorts = List.copyOf(sorts);
	}
}
