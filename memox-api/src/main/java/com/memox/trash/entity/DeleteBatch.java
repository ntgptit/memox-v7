package com.memox.trash.entity;

import java.time.Instant;

import com.memox.trash.enums.TrashItemType;

/**
 * One deletion, as the thing a restore acts on.
 *
 * <p>A batch has exactly one item root (BR-256). Deleting fifty cards opens fifty batches sharing
 * one {@code deletedAt}, not one batch listing fifty roots — someone who deletes fifty may want
 * three of them back, and a shared batch could only offer that through a partial restore, which
 * BR-262 does not have: it revives exactly the rows carrying the batch id.
 *
 * <p><strong>The batch relation lives on the row, never derived from the current parent</strong>
 * (BR-258). Where a row sits answers <em>where it is</em>; the batch id it carries answers
 * <em>what it went with</em>, and only the second decides what comes back.
 */
public record DeleteBatch(String id, TrashItemType itemType, String rootItemId, Instant deletedAt) {
}
