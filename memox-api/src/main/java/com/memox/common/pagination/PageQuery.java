package com.memox.common.pagination;

import java.util.List;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

import lombok.Builder;
import lombok.Singular;
import lombok.Value;

/**
 * A request for one page of a list, in the units the API publishes: pages, not row offsets.
 *
 * <p>Pages are zero-based, so page 0 is the first page and {@link #offset()} is simply
 * {@code page * size}. That arithmetic lives here and nowhere else — every statement in the module
 * takes a {@link PageSlice}, so no mapper and no service re-derives it and gets it wrong by one.
 *
 * <p>The {@code search} field named by {@code pagination-contract.md} is deliberately absent. No
 * statement in this module searches yet, so declaring it would publish a query parameter the SQL
 * ignores — a client would filter, get everything back, and have no way to tell. It arrives with
 * the Phase 2 statements that can honour it.
 *
 * @param <TSort> the feature's sort enum; the generic is what stops one feature's sort fields being
 *                accepted on another feature's endpoint
 */
@Value
@Builder(toBuilder = true)
public class PageQuery<TSort extends Enum<TSort>> {

	@Builder.Default
	@Min(PaginationConstants.MIN_PAGE)
	int page = PaginationConstants.DEFAULT_PAGE;

	@Builder.Default
	@Min(PaginationConstants.MIN_SIZE)
	@Max(PaginationConstants.MAX_SIZE)
	int size = PaginationConstants.DEFAULT_SIZE;

	@Singular
	List<SortSpec<TSort>> sorts;

	/**
	 * The row offset this page starts at.
	 *
	 * <p>Widened to {@code long} on purpose: {@code page * size} at the top of the int range
	 * overflows to a negative offset, and PostgreSQL answers a negative OFFSET with an error rather
	 * than with the first page. The multiplication is done in long arithmetic so it cannot wrap.
	 */
	public long offset() {
		return (long) page * size;
	}
}
