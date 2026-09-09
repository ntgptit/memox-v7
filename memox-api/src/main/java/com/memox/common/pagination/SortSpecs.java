package com.memox.common.pagination;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

import com.memox.common.error.ValidationFailedException;

import lombok.experimental.UtilityClass;

/**
 * Turns the {@code sort} query parameter into typed {@link SortSpec}s, or refuses it.
 *
 * <p>The wire form is {@code sort=createdAt:desc}, and multi-sort is either repetition
 * ({@code sort=a:asc&sort=b:desc}) or one comma-separated value ({@code sort=a:asc,b:desc}) —
 * Spring splits a query parameter on commas when binding it to a {@code List<String>}, so both
 * arrive here identically.
 *
 * <p>That comma split is also why the field and its direction are joined by a colon rather than by
 * a comma. Written {@code sort=createdAt,desc}, the pair is torn in two before this class ever sees
 * it, and {@code desc} is then read as a field name — which is exactly what happened, and the
 * failure said "unknown sort field" while pointing at a perfectly good direction.
 *
 * <p>An unrecognised token is a 400, never a silently dropped sort. A request that asked for an
 * ordering and got an arbitrary one back is indistinguishable from a working one until somebody
 * scrolls. The rejection lists the tokens the endpoint accepts and does not echo what arrived, so
 * the parameter cannot reflect attacker-chosen text back into a response.
 */
@UtilityClass
public class SortSpecs {

	public static final String SORT_PARAMETER = "sort";

	private static final String FIELD_DIRECTION_SEPARATOR = ":";
	private static final int FIELD_ONLY = 1;
	private static final int FIELD_AND_DIRECTION = 2;

	public <TSort extends Enum<TSort> & SortField> List<SortSpec<TSort>> parse(
			List<String> rawSorts, Class<TSort> fieldType) {
		if (rawSorts == null) {
			return List.of();
		}
		return rawSorts.stream()
				.filter(raw -> !raw.isBlank())
				.map(raw -> parseOne(raw, fieldType))
				.toList();
	}

	private <TSort extends Enum<TSort> & SortField> SortSpec<TSort> parseOne(
			String rawSort, Class<TSort> fieldType) {
		final var parts = rawSort.split(FIELD_DIRECTION_SEPARATOR, -1);
		if (parts.length != FIELD_ONLY && parts.length != FIELD_AND_DIRECTION) {
			throw new ValidationFailedException(SORT_PARAMETER,
					"expected field or field:direction; allowed fields are " + allowedTokens(fieldType));
		}
		return new SortSpec<>(resolveField(parts[0], fieldType), resolveDirection(parts));
	}

	private <TSort extends Enum<TSort> & SortField> TSort resolveField(String token, Class<TSort> fieldType) {
		for (final TSort candidate : fieldType.getEnumConstants()) {
			if (candidate.getToken().equalsIgnoreCase(token.trim())) {
				return candidate;
			}
		}
		throw new ValidationFailedException(SORT_PARAMETER,
				"unknown sort field; allowed fields are " + allowedTokens(fieldType));
	}

	private SortDirection resolveDirection(String[] parts) {
		if (parts.length == FIELD_ONLY) {
			return SortDirection.ASC;
		}
		final var direction = SortDirection.fromToken(parts[1].trim());
		if (direction == null) {
			throw new ValidationFailedException(SORT_PARAMETER, "sort direction must be asc or desc");
		}
		return direction;
	}

	private <TSort extends Enum<TSort> & SortField> String allowedTokens(Class<TSort> fieldType) {
		return Arrays.stream(fieldType.getEnumConstants())
				.map(SortField::getToken)
				.collect(Collectors.joining(", "));
	}
}
