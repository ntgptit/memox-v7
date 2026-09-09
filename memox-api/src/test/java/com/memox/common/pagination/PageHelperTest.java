package com.memox.common.pagination;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;

import org.junit.jupiter.api.Test;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

class PageHelperTest {

	private static final SortColumn TIE_BREAKER = new SortColumn("id", SortDirection.ASC);
	private static final List<SortColumn> DEFAULT_SORT = List.of(new SortColumn("position", SortDirection.ASC));

	@Test
	void createsTypedPageMetadataFromPageSizeAndTotal() {
		final var query = PageQuery.<TestSortField>builder().page(1).size(2).build();

		final PagingResponse<String> page = PageHelper.create(query, List.of("third", "fourth"), 5);

		assertThat(page.getItems()).containsExactly("third", "fourth");
		assertThat(page.getPage()).isEqualTo(1);
		assertThat(page.getSize()).isEqualTo(2);
		assertThat(page.getTotalItems()).isEqualTo(5);
		assertThat(page.getTotalPages()).isEqualTo(3);
		assertThat(page.isHasNext()).isTrue();
		assertThat(page.isHasPrevious()).isTrue();
		assertThat(page.map(String::length).getItems()).containsExactly(5, 6);
	}

	@Test
	void createsAnEmptyFirstPageWithoutPreviousOrNextPage() {
		final var page = PageHelper.create(PageQuery.<TestSortField>builder().build(), List.<Integer>of(), 0);

		assertThat(page.getPage()).isZero();
		assertThat(page.getTotalPages()).isZero();
		assertThat(page.isHasNext()).isFalse();
		assertThat(page.isHasPrevious()).isFalse();
	}

	/**
	 * The conversion the whole contract turns on: the API counts pages, the database counts rows.
	 */
	@Test
	void derivesTheRowOffsetFromPageAndSize() {
		assertThat(PageQuery.<TestSortField>builder().page(0).size(20).build().offset()).isZero();
		assertThat(PageQuery.<TestSortField>builder().page(3).size(20).build().offset()).isEqualTo(60);
	}

	/**
	 * {@code page * size} in int arithmetic wraps negative near the top of the range, and PostgreSQL
	 * answers a negative OFFSET with an error rather than with the first page — a 500 for a request
	 * that is merely absurd. The multiplication is widened to long so it cannot wrap.
	 */
	@Test
	void doesNotWrapTheOffsetAtTheTopOfTheIntegerRange() {
		final var query = PageQuery.<TestSortField>builder().page(Integer.MAX_VALUE).size(100).build();

		assertThat(query.offset()).isEqualTo(214_748_364_700L);
	}

	@Test
	void appliesTheDefaultSortWhenTheRequestAsksForNone() {
		final var slice = PageHelper.slice(
				PageQuery.<TestSortField>builder().build(), DEFAULT_SORT, TIE_BREAKER);

		assertThat(slice.sorts()).containsExactly(
				new SortColumn("position", SortDirection.ASC),
				new SortColumn("id", SortDirection.ASC));
	}

	@Test
	void translatesRequestedSortFieldsIntoTheirColumnsAndAppendsTheTieBreaker() {
		final var query = PageQuery.<TestSortField>builder()
				.sort(new SortSpec<>(TestSortField.CREATED_AT, SortDirection.DESC))
				.sort(new SortSpec<>(TestSortField.LABEL, SortDirection.ASC))
				.build();

		final var slice = PageHelper.slice(query, DEFAULT_SORT, TIE_BREAKER);

		assertThat(slice.sorts()).containsExactly(
				new SortColumn("created_at", SortDirection.DESC),
				new SortColumn("label", SortDirection.ASC),
				new SortColumn("id", SortDirection.ASC));
	}

	/**
	 * A tie-breaker appended twice would be {@code ORDER BY id ASC, id ASC} — harmless, but it also
	 * means the request's own direction on that column was silently overridden by the second entry.
	 */
	@Test
	void doesNotRepeatTheTieBreakerWhenTheRequestAlreadyOrdersByThatColumn() {
		final var query = PageQuery.<TestSortField>builder()
				.sort(new SortSpec<>(TestSortField.ID, SortDirection.DESC))
				.build();

		final var slice = PageHelper.slice(query, DEFAULT_SORT, TIE_BREAKER);

		assertThat(slice.sorts()).containsExactly(new SortColumn("id", SortDirection.DESC));
	}

	/**
	 * An empty sort list renders {@code ORDER BY LIMIT ...} — a syntax error a real database would
	 * report at run time. The slice refuses to exist instead.
	 */
	@Test
	void refusesASliceWithNothingToOrderBy() {
		assertThatThrownBy(() -> new PageSlice(10, 0, List.of()))
				.isInstanceOf(IllegalArgumentException.class)
				.hasMessageContaining("ORDER BY cannot be empty");
	}

	@Getter
	@RequiredArgsConstructor
	private enum TestSortField implements SortField {

		ID("id", "id"),
		LABEL("label", "label"),
		CREATED_AT("createdAt", "created_at");

		private final String token;
		private final String column;
	}
}
