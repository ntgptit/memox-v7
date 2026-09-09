package com.memox.card.entity;

import java.time.Instant;
import java.util.List;

import com.memox.common.scheduler.SchedulerType;

/**
 * One row of the management list: the card, its study state, and its tag names.
 *
 * <p>All three in one statement, and all three from one snapshot. Reading the state separately
 * would let a row show content from before an edit beside a schedule from after it.
 *
 * <p>The state columns are carried whole rather than trimmed to what today's screen renders. This
 * is a port; which of them a client shows is the client's decision, and dropping one here would be
 * a contract change disguised as tidying.
 */
public record CardListItem(
		String id,
		String deckId,
		String front,
		String back,
		boolean flagged,
		String example,
		String hint,
		String pronunciation,
		Instant createdAt,
		Instant updatedAt,
		SchedulerType schedulerType,
		int schedulerGeneration,
		Instant learnedAt,
		Instant dueAt,
		Instant lastAnsweredAt,
		int answerCount,
		int lapseCount,
		Integer currentBox,
		Double easeFactor,
		Integer intervalDays,
		Integer repetitions,
		List<String> tagNames) {

	public CardListItem {
		tagNames = List.copyOf(tagNames);
	}
}
