package com.memox.common.pagination;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;

import org.junit.jupiter.api.Test;

import com.memox.common.error.ValidationFailedException;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * The transport-layer boundary that keeps client text out of an ORDER BY clause.
 *
 * <p>Everything downstream — {@link PageHelper#slice}, {@link PageSlice}, the {@code orderBySlice}
 * fragment in both mapper XMLs — assumes a sort column can only have come from an enum constant.
 * That assumption is only true because this class refuses everything else, so these are the tests
 * that hold the safety argument up.
 */
class SortSpecsTest {

	@Test
	void treatsAnAbsentSortParameterAsNoSort() {
		assertThat(SortSpecs.parse(null, TestSortField.class)).isEmpty();
		assertThat(SortSpecs.parse(List.of(), TestSortField.class)).isEmpty();
		assertThat(SortSpecs.parse(List.of("  "), TestSortField.class)).isEmpty();
	}

	@Test
	void defaultsToAscendingWhenOnlyAFieldIsGiven() {
		assertThat(SortSpecs.parse(List.of("createdAt"), TestSortField.class))
				.containsExactly(new SortSpec<>(TestSortField.CREATED_AT, SortDirection.ASC));
	}

	@Test
	void readsFieldAndDirectionCaseInsensitivelyAndKeepsTheGivenOrder() {
		final var sorts = SortSpecs.parse(List.of("CREATEDAT:DESC", "label : asc"), TestSortField.class);

		assertThat(sorts).containsExactly(
				new SortSpec<>(TestSortField.CREATED_AT, SortDirection.DESC),
				new SortSpec<>(TestSortField.LABEL, SortDirection.ASC));
	}

	/**
	 * The payload is a working ORDER BY injection against any implementation that concatenates the
	 * token. It never becomes SQL, and the rejection does not echo it back either.
	 */
	@Test
	void refusesAFieldTheEnumDoesNotName() {
		assertThatThrownBy(() -> SortSpecs.parse(List.of("created_at ASC; (SELECT 1)"), TestSortField.class))
				.isInstanceOf(ValidationFailedException.class)
				.hasFieldOrPropertyWithValue("field", "sort")
				.hasFieldOrPropertyWithValue("reason",
						"unknown sort field; allowed fields are label, createdAt")
				.extracting(exception -> ((ValidationFailedException) exception).getReason())
				.asString()
				.doesNotContain("SELECT");
	}

	@Test
	void refusesADirectionThatIsNeitherAscNorDesc() {
		assertThatThrownBy(() -> SortSpecs.parse(List.of("label:sideways"), TestSortField.class))
				.isInstanceOf(ValidationFailedException.class)
				.hasFieldOrPropertyWithValue("reason", "sort direction must be asc or desc");
	}

	@Test
	void refusesAnEntryThatIsNeitherAFieldNorAFieldAndDirection() {
		assertThatThrownBy(() -> SortSpecs.parse(List.of("label:asc:extra"), TestSortField.class))
				.isInstanceOf(ValidationFailedException.class)
				.hasFieldOrPropertyWithValue("field", "sort");
	}

	@Getter
	@RequiredArgsConstructor
	private enum TestSortField implements SortField {

		LABEL("label", "label"),
		CREATED_AT("createdAt", "created_at");

		private final String token;
		private final String column;
	}
}
