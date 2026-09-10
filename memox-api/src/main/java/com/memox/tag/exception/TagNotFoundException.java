package com.memox.tag.exception;

import com.memox.common.error.ApiErrorCode;
import com.memox.common.error.MemoxException;

import lombok.Getter;

/**
 * A tag id that resolved to nothing.
 *
 * <p>The id travels in the message, which is logged; the name never does. A tag name is user
 * material on the same footing as a card face (BR-51, BR-52, BR-267).
 */
@Getter
public class TagNotFoundException extends MemoxException {

	private static final long serialVersionUID = 6112430094427518351L;

	private final String tagId;

	public TagNotFoundException(String tagId) {
		super(ApiErrorCode.TAG_NOT_FOUND, "tagId=" + tagId);
		this.tagId = tagId;
	}
}
