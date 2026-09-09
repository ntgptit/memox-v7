package com.memox.deck.entity;

import java.time.Instant;

import com.memox.deck.enums.DeckContentType;
import com.memox.common.scheduler.SchedulerType;

/**
 * One root deck with the seven counts the Library screen shows beside it.
 *
 * <p>Every count reaches its cards through {@code root_deck_id}, never by walking
 * {@code parent_deck_id}: a card three levels down belongs to the root just as much as one directly
 * under it, and {@code COALESCE(parent_deck_id, id)} silently returns the wrong deck from the third
 * level down.
 *
 * <p>{@code oldestDueAt} and {@code nextDueAt} are nullable because a deck with nothing due and
 * nothing scheduled has neither, and zero would be a different claim from absent.
 */
public record DeckSummary(
		String id,
		String name,
		String rootDeckId,
		DeckContentType contentType,
		SchedulerType schedulerType,
		int siblingPosition,
		long totalCardCount,
		long newCardCount,
		long dueCardCount,
		long overdueCardCount,
		Instant oldestDueAt,
		long learnedCardCount,
		long subDeckCount,
		Instant nextDueAt,
		Instant createdAt,
		Instant updatedAt) {
}
