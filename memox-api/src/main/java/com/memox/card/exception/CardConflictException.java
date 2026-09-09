package com.memox.card.exception;

import com.memox.common.error.ApiErrorCode;
import com.memox.common.error.MemoxException;

import lombok.Getter;

/**
 * A card rule that refused the write, together with what it refused it on.
 *
 * <p>The detail is an id — a card or a deck — never a card face. Card content is the most private
 * thing this API holds (BR-51, BR-52) and the exception message is logged.
 */
@Getter
public class CardConflictException extends MemoxException {

	private static final long serialVersionUID = 5570392214404183512L;

	private final String subjectId;

	public CardConflictException(ApiErrorCode errorCode, String subjectId) {
		super(errorCode, "id=" + subjectId);
		this.subjectId = subjectId;
	}
}
