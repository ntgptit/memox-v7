package com.memox.tag.entity;

import java.time.Instant;

/**
 * One tag row.
 *
 * <p>{@code owner_id} is on the table and deliberately not here (AD-03): the column exists so that
 * auth can land without a migration, but this API has no principal to fill it and no other entity
 * carries it either. A field every write sets to null is not a fact, it is a placeholder.
 */
public record Tag(String id, String name, String nameFolded, Instant createdAt) {
}
