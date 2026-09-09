package com.memox.deck.dto.request;

import com.memox.deck.service.DeckLimits;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

/**
 * Where a deck should sit among its siblings.
 *
 * @param targetPosition zero-based index among the ACTIVE siblings, which is what the user sees.
 *                       It is not the raw {@code sibling_position} column: tombstoned siblings keep
 *                       a value there and hold no place in the visible order.
 */
public record ReorderDeckRequest(
		@NotNull @Min(DeckLimits.MIN_SIBLING_POSITION) Integer targetPosition) {
}
