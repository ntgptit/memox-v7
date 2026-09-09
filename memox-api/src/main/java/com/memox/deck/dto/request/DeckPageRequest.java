package com.memox.deck.dto.request;

import java.util.List;

import com.memox.common.pagination.PageQuery;
import com.memox.common.pagination.PaginationConstants;
import com.memox.common.pagination.SortSpecs;
import com.memox.deck.enums.DeckSortField;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/**
 * The query string of the deck list endpoint, bound and validated as one object.
 *
 * <p>All three components are nullable because "absent" and "zero" are different requests: a
 * missing {@code page} means the configured default, while {@code page=0} is the first page asked
 * for explicitly. Bean Validation skips nulls, so the bounds below constrain what was sent without
 * rejecting what was not.
 *
 * @param page zero-based page index; absent means {@code memox.pagination.default-page}
 * @param size rows per page; absent means {@code memox.pagination.default-size}
 * @param sort repeated {@code field} or {@code field:direction} entries, applied in order
 */
public record DeckPageRequest(
		@Min(PaginationConstants.MIN_PAGE) Integer page,
		@Min(PaginationConstants.MIN_SIZE) @Max(PaginationConstants.MAX_SIZE) Integer size,
		List<String> sort) {

	/**
	 * Spring binds an absent {@code sort} as null and a present one as a list it still owns; both
	 * are normalised here so the rest of the type can treat {@code sort} as an immutable list.
	 */
	public DeckPageRequest {
		sort = sort == null ? List.of() : List.copyOf(sort);
	}

	public PageQuery<DeckSortField> toPageQuery(int defaultPage, int defaultSize) {
		return PageQuery.<DeckSortField>builder()
				.page(page == null ? defaultPage : page)
				.size(size == null ? defaultSize : size)
				.sorts(SortSpecs.parse(sort, DeckSortField.class))
				.build();
	}
}
