package com.memox.common.pagination;

/**
 * The two orderings a sort can take, named exactly as SQL names them.
 *
 * <p>The constant name IS the SQL keyword, which is what lets {@code ORDER BY} be rendered from a
 * {@link SortColumn} without any text arriving from the client: the only two direction values that
 * can ever reach a statement are the two written here.
 */
public enum SortDirection {

	ASC,
	DESC;

	/**
	 * Resolves the token a client sends, case-insensitively.
	 *
	 * @return the direction, or {@code null} when the token names neither of them — the caller
	 *         decides how a bad token is reported, because only it knows which parameter carried it
	 */
	public static SortDirection fromToken(String token) {
		for (final SortDirection direction : values()) {
			if (direction.name().equalsIgnoreCase(token)) {
				return direction;
			}
		}
		return null;
	}
}
