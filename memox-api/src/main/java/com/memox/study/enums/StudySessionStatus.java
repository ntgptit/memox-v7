package com.memox.study.enums;

import com.memox.common.mybatis.PersistableEnum;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * How a study session ended, or that it has not (BR-79).
 *
 * <p>Five values, matching the column's CHECK constraint exactly. A terminal session stays as it
 * ended (BR-86): nothing here rewrites a {@code completed} or {@code abandoned} session, which is
 * why every lookup that closes sessions filters on {@link #IN_PROGRESS} alone.
 */
@Getter
@RequiredArgsConstructor
public enum StudySessionStatus implements PersistableEnum {

	IN_PROGRESS("in_progress"),
	COMPLETED("completed"),
	ABANDONED("abandoned"),
	INVALIDATED("invalidated"),
	FAILED("failed");

	private final String value;
}
