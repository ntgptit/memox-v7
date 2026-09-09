package com.memox.common.pagination;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import lombok.experimental.UtilityClass;

/**
 * The two translations every list endpoint needs: a request into a {@link PageSlice}, and a result
 * into a {@link PagingResponse}.
 */
@UtilityClass
public class PageHelper {

	public <T, TSort extends Enum<TSort>> PagingResponse<T> create(
			PageQuery<TSort> pageQuery, List<T> items, long totalItems) {
		Objects.requireNonNull(pageQuery, "pageQuery must not be null");
		Objects.requireNonNull(items, "items must not be null");
		if (totalItems < 0) {
			throw new IllegalArgumentException("totalItems must not be negative");
		}

		return PagingResponse.<T>builder()
				.items(List.copyOf(items))
				.page(pageQuery.getPage())
				.size(pageQuery.getSize())
				.totalItems(totalItems)
				.totalPages(totalPages(totalItems, pageQuery.getSize()))
				.hasNext(pageQuery.offset() + pageQuery.getSize() < totalItems)
				.hasPrevious(pageQuery.getPage() > PaginationConstants.MIN_PAGE)
				.build();
	}

	/**
	 * Resolves a request's sorts into the columns SQL will order by.
	 *
	 * <p>Three things happen here that a caller would otherwise have to remember at every endpoint:
	 * an unsorted request falls back to {@code defaultSorts}; the tie-breaker is appended unless the
	 * request already orders by that column; and the enum's own {@link SortField#getColumn()} is
	 * the only source of a column name.
	 *
	 * <p>The tie-breaker is not optional and not a detail. LIMIT/OFFSET over a non-unique ordering
	 * lets PostgreSQL return the same row on two pages and skip another entirely, because nothing
	 * obliges it to break ties the same way twice.
	 */
	public <TSort extends Enum<TSort> & SortField> PageSlice slice(
			PageQuery<TSort> pageQuery, List<SortColumn> defaultSorts, SortColumn tieBreaker) {
		final var requested = pageQuery.getSorts().stream()
				.map(spec -> new SortColumn(spec.field().getColumn(), spec.direction(), spec.field().getNulls()))
				.toList();
		final var base = requested.isEmpty() ? defaultSorts : requested;
		final var sorts = new ArrayList<>(base);
		if (base.stream().noneMatch(sort -> sort.column().equals(tieBreaker.column()))) {
			sorts.add(tieBreaker);
		}
		return new PageSlice(pageQuery.getSize(), pageQuery.offset(), sorts);
	}

	private int totalPages(long totalItems, int size) {
		return (int) ((totalItems + size - 1) / size);
	}
}
