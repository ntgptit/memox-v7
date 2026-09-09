package com.memox.card.dto.request;

import java.time.Instant;

import com.memox.card.entity.CardHistoryCursor;
import com.memox.common.error.ValidationFailedException;
import com.memox.common.pagination.PaginationConstants;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/**
 * The cursor and page size for one request of a card's history.
 *
 * <p>The cursor is two parameters rather than one opaque token: both halves are meaningful, and a
 * client resuming a page can see what it is resuming from.
 *
 * <p><strong>Half a cursor is refused.</strong> Sending {@code answeredAt} without {@code cursorId}
 * would silently read as "first page" and quietly repeat rows the client has already shown — the
 * duplicate BR-241 forbids, arriving as a client bug rather than an error.
 *
 * @param limit absent means {@code memox.pagination.default-size}
 */
public record CardHistoryRequest(
		Instant answeredAt,
		String cursorId,
		@Min(PaginationConstants.MIN_SIZE) @Max(PaginationConstants.MAX_SIZE) Integer limit) {

	public CardHistoryCursor toCursor() {
		if (answeredAt == null && cursorId == null) {
			return null;
		}
		if (answeredAt == null || cursorId == null) {
			throw new ValidationFailedException("cursor",
					"answeredAt and cursorId must be sent together; half a cursor would silently "
							+ "restart at the first page");
		}
		return new CardHistoryCursor(answeredAt, cursorId);
	}

	public int effectiveLimit() {
		if (limit == null) {
			return PaginationConstants.DEFAULT_SIZE;
		}
		return limit;
	}
}
