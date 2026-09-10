package com.memox.tag.dto.response;

import com.memox.tag.entity.Tag;

/**
 * One tag, as a chip renders it.
 *
 * <p>{@code nameFolded} stays inside: it is how the tag is compared, not how it is shown, and a
 * client that rendered it would show a spelling nobody typed.
 */
public record TagResponse(String id, String name) {

	public static TagResponse from(Tag tag) {
		return new TagResponse(tag.id(), tag.name());
	}
}
