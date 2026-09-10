package com.memox.trash.entity;

/**
 * A deleted deck, read without the active filter every other statement carries.
 *
 * <p>Two fields, because a restore needs to ask exactly one question of the tombstone: was this a
 * root, or a sub-deck? Everything else about where it goes is a property of the target, which is
 * read live. Its stored {@code parent_deck_id} is also the whole of "where it was" — a tombstone
 * keeps pointing at its old home, which is why Trash needs no origin column of its own.
 */
public record TombstoneDeck(String id, String parentDeckId) {
}
