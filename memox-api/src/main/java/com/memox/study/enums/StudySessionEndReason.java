package com.memox.study.enums;

import com.memox.common.mybatis.PersistableEnum;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * Why a study session ended, stored rather than inferred (BR-80, AD-11).
 *
 * <p><strong>Seven values, not the five BR-80's prose lists.</strong> That row is stale against its
 * own document: BR-259 requires {@code content_deleted} and BR-164 requires
 * {@code scheduler_changed}, and the column's CHECK constraint carries all seven. Restricting this
 * enum to BR-80's list would reject the very value BR-259 demands. The mismatch is recorded as a
 * documents task rather than fixed here — {@code docs/business-rules.md} is frozen for MVP.
 *
 * <p>{@link #CONTENT_DELETED} is deliberately its own value and not the nearest existing one.
 * {@code SCHEDULER_RESET} would be a lie: nothing about the scheduler changed, the material went to
 * Trash — and only one of those two is undone by pressing Undo.
 */
@Getter
@RequiredArgsConstructor
public enum StudySessionEndReason implements PersistableEnum {

	USER_EXIT("user_exit"),
	SCHEDULER_RESET("scheduler_reset"),
	SCHEDULER_CHANGED("scheduler_changed"),
	STALE_GENERATION("stale_generation"),
	PERSISTENCE_ERROR("persistence_error"),
	INTERRUPTED("interrupted"),
	CONTENT_DELETED("content_deleted");

	private final String value;
}
