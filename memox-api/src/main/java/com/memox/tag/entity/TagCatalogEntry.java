package com.memox.tag.entity;

/**
 * One row of the management catalog: a tag and how many <em>active</em> cards carry it (BR-230).
 *
 * <p>A tag nothing points at keeps its row with a count of zero. That is not an accident of the
 * query shape — it is what the catalog is for, because a tag no card carries is precisely the one a
 * user opens this screen to delete.
 */
public record TagCatalogEntry(String id, String name, long cardCount) {
}
