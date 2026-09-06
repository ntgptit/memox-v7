package com.memox.common.pagination;

import java.util.List;
import java.util.Objects;

import lombok.experimental.UtilityClass;

@UtilityClass
public class PageHelper {

	public <T> PagingResponse<T> create(PageQuery pageQuery, List<T> items, long totalItems) {
		Objects.requireNonNull(pageQuery, "pageQuery must not be null");
		Objects.requireNonNull(items, "items must not be null");
		if (totalItems < 0) {
			throw new IllegalArgumentException("totalItems must not be negative");
		}

		final var immutableItems = List.copyOf(items);
		final var totalPages = totalPages(totalItems, pageQuery.getLimit());
		final long consumedItems = (long) pageQuery.getOffset() + immutableItems.size();
		return PagingResponse.<T>builder()
				.items(immutableItems)
				.limit(pageQuery.getLimit())
				.offset(pageQuery.getOffset())
				.totalItems(totalItems)
				.totalPages(totalPages)
				.hasNext(consumedItems < totalItems)
				.hasPrevious(pageQuery.getOffset() > PaginationConstants.MIN_OFFSET)
				.build();
	}

	private long totalPages(long totalItems, int limit) {
		if (totalItems == 0) {
			return 0;
		}
		return ((totalItems - 1) / limit) + 1;
	}
}
