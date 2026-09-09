package com.memox.card.entity;

import java.time.Instant;

import com.memox.common.scheduler.SchedulerType;

/**
 * One recorded answer, exactly as the row stored it.
 *
 * <p><strong>Every stored column, and that is the contract.</strong> BR-242 says the screen shows
 * what the row stored, so a column dropped from the projection is a fact that silently stops being
 * displayed — the Drift source uses {@code SELECT *} for precisely this reason, and warns about it
 * in the comment above the statement. The Phase 2 plan's projection dropped
 * {@code comparison_version}; this record and the statement behind it carry all twenty.
 *
 * <p>{@code usedHint} is a nullable {@link Boolean}: the column is nullable, and "we do not know"
 * is a different answer from "no hint was used".
 *
 * <p>{@code kind}, {@code mode}, {@code action}, {@code outcomeReason} and {@code direction} stay
 * strings. Each has a CHECK constraint that is effectively an enum, but nothing reads them as one
 * yet — Phase 3 writes history and can introduce the types where they will be used.
 */
public record CardHistoryEntry(
		String id,
		String cardId,
		String sessionId,
		SchedulerType schedulerType,
		int schedulerGeneration,
		String kind,
		String mode,
		String outcomeReason,
		Integer comparisonVersion,
		Boolean usedHint,
		String action,
		Instant answeredAt,
		Instant nextDueAt,
		Integer previousBox,
		Integer nextBox,
		Double previousEaseFactor,
		Double nextEaseFactor,
		Integer previousIntervalDays,
		Integer nextIntervalDays,
		String direction) {
}
