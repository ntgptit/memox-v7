package com.memox.tag.dto.response;

import com.memox.tag.entity.TagCatalogEntry;

/** One catalog row: the tag as it is spelled, and how many active cards carry it (BR-230). */
public record TagCatalogResponse(String id, String name, long cardCount) {

	public static TagCatalogResponse from(TagCatalogEntry entry) {
		return new TagCatalogResponse(entry.id(), entry.name(), entry.cardCount());
	}
}
