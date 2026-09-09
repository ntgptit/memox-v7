package com.memox.common.pagination;

import java.util.List;
import java.util.function.Function;

import lombok.Builder;
import lombok.Value;

@Value
@Builder(toBuilder = true)
public class PagingResponse<T> {

	List<T> items;
	int page;
	int size;
	long totalItems;
	int totalPages;
	boolean hasNext;
	boolean hasPrevious;

	public <R> PagingResponse<R> map(Function<? super T, R> mapper) {
		return PagingResponse.<R>builder()
				.items(items.stream().map(mapper).toList())
				.page(page)
				.size(size)
				.totalItems(totalItems)
				.totalPages(totalPages)
				.hasNext(hasNext)
				.hasPrevious(hasPrevious)
				.build();
	}
}
