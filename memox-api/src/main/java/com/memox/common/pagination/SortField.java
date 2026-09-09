package com.memox.common.pagination;

/**
 * What a feature's sort enum has to know: the token clients write, and the column SQL orders by.
 *
 * <p>The two are deliberately separate. {@link #getToken()} belongs to the published API and
 * matches the camelCase field names in the response payload; {@link #getColumn()} is the snake_case
 * database column and never appears on the wire. Keeping them apart means the schema can be renamed
 * without breaking a client, and it means the only strings that can reach an ORDER BY clause are
 * the ones an enum constant declares.
 */
public interface SortField {

	/** The value a client writes in the {@code sort} query parameter. */
	String getToken();

	/** The database column this field orders by. Never client-supplied. */
	String getColumn();
}
