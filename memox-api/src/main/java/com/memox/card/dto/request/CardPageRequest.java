package com.memox.card.dto.request;

import java.util.List;

import com.memox.card.enums.CardSortField;
import com.memox.common.pagination.PageQuery;
import com.memox.common.pagination.PaginationConstants;
import com.memox.common.pagination.SortSpecs;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/**
 * The query string of the card list endpoint, bound and validated as one object.
 *
 * <p>Deliberately a separate type from {@code DeckPageRequest} rather than a shared base: the sort
 * enum differs, and that difference is the whole point of the generic. A shared supertype would
 * have to erase it, and the two endpoints would start accepting each other's sort tokens.
 *
 * @param page zero-based page index; absent means {@code memox.pagination.default-page}
 * @param size rows per page; absent means {@code memox.pagination.default-size}
 * @param sort repeated {@code field} or {@code field:direction} entries, applied in order
 */
public record CardPageRequest(
		@Min(PaginationConstants.MIN_PAGE) Integer page,
		@Min(PaginationConstants.MIN_SIZE) @Max(PaginationConstants.MAX_SIZE) Integer size,
		List<String> sort) {

	/**
	 * Spring binds an absent {@code sort} as null and a present one as a list it still owns; both
	 * are normalised here so the rest of the type can treat {@code sort} as an immutable list.
	 */
	public CardPageRequest {
		sort = sort == null ? List.of() : List.copyOf(sort);
	}

	public PageQuery<CardSortField> toPageQuery(int defaultPage, int defaultSize) {
		return PageQuery.<CardSortField>builder()
				.page(page == null ? defaultPage : page)
				.size(size == null ? defaultSize : size)
				.sorts(SortSpecs.parse(sort, CardSortField.class))
				.build();
	}
}
