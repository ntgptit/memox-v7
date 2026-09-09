package com.memox.deck.dto.response;

import java.time.Instant;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.memox.deck.entity.DeckLevelChild;

/**
 * A direct child with the aggregate of its whole subtree.
 *
 * <p>{@code subDeckCount} is the exception and counts direct children only — the same asymmetry the
 * statement has, published rather than smoothed over.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record DeckLevelChildResponse(
		DeckResponse deck,
		String inheritedSchedulerType,
		long totalCardCount,
		long newCardCount,
		long dueCardCount,
		long overdueCardCount,
		Instant oldestDueAt,
		long learnedCardCount,
		long subDeckCount) {

	public static DeckLevelChildResponse from(DeckLevelChild child) {
		return new DeckLevelChildResponse(DeckResponse.from(child.child()),
				schedulerValue(child), child.totalCardCount(), child.newCardCount(),
				child.dueCardCount(), child.overdueCardCount(), child.oldestDueAt(),
				child.learnedCardCount(), child.subDeckCount());
	}

	private static String schedulerValue(DeckLevelChild child) {
		if (child.inheritedSchedulerType() == null) {
			return null;
		}
		return child.inheritedSchedulerType().getValue();
	}
}
