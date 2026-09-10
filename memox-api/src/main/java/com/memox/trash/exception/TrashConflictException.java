package com.memox.trash.exception;

import com.memox.common.error.ApiErrorCode;
import com.memox.common.error.MemoxException;

import lombok.Getter;

/**
 * A restore or a purge the current state refuses.
 *
 * <p>It carries the error code of the rule that refused it, and for a restore that code is usually
 * a <em>deck</em> code — {@code DECK_DEPTH_EXCEEDED}, {@code PARENT_HOLDS_CARDS},
 * {@code DECK_CROSS_ROOT_MOVE}. That is deliberate: BR-261 says a restore is held to the move's
 * rules and forbids a second rule set for it, so it must also refuse with the move's reasons rather
 * than translate them into private ones.
 *
 * <p>{@code RESTORE_TARGET_INVALID} is left for what only a restore can get wrong: the level. A
 * root deck goes back to the top level and nothing else does.
 */
@Getter
public class TrashConflictException extends MemoxException {

	private static final long serialVersionUID = 7563299174532002119L;

	private final String subjectId;

	public TrashConflictException(ApiErrorCode errorCode, String subjectId) {
		super(errorCode, "id=" + subjectId);
		this.subjectId = subjectId;
	}
}
