package com.memox.tag.exception;

import com.memox.common.error.ApiErrorCode;
import com.memox.common.error.MemoxException;

import lombok.Getter;

/**
 * A tag rule that refused the write, named by the row it refused on.
 *
 * <p>The subject is a card id — the card that sits at BR-94's ceiling — never the name that was
 * being attached.
 */
@Getter
public class TagConflictException extends MemoxException {

	private static final long serialVersionUID = 3252878255413178610L;

	private final String subjectId;

	public TagConflictException(ApiErrorCode errorCode, String subjectId) {
		super(errorCode, "id=" + subjectId);
		this.subjectId = subjectId;
	}
}
