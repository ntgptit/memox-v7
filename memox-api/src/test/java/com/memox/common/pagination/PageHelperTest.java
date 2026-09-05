package com.memox.common.pagination;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;

import org.junit.jupiter.api.Test;

class PageHelperTest {

	@Test
	void createsTypedPageMetadataFromLimitOffsetAndTotal() {
		final var query = PageQuery.builder().limit(2).offset(2).build();

		final PagingResponse<String> page = PageHelper.create(query, List.of("third", "fourth"), 5);

		assertThat(page.getItems()).containsExactly("third", "fourth");
		assertThat(page.getLimit()).isEqualTo(2);
		assertThat(page.getOffset()).isEqualTo(2);
		assertThat(page.getTotalItems()).isEqualTo(5);
		assertThat(page.getTotalPages()).isEqualTo(3);
		assertThat(page.isHasNext()).isTrue();
		assertThat(page.isHasPrevious()).isTrue();
		assertThat(page.map(String::length).getItems()).containsExactly(5, 6);
	}

	@Test
	void createsAnEmptyFirstPageWithoutPreviousOrNextPage() {
		final var page = PageHelper.create(PageQuery.builder().build(), List.<Integer>of(), 0);

		assertThat(page.getTotalPages()).isZero();
		assertThat(page.isHasNext()).isFalse();
		assertThat(page.isHasPrevious()).isFalse();
	}
}
