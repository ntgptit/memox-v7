package com.memox.trash.service;

/**
 * What one retention sweep did.
 *
 * <p>{@code skippedBatches} is not an error count. A batch whose cascade would reach a row this
 * sweep is not allowed to remove is left whole and tried again next time (BR-265) — usually because
 * a descendant's own thirty days have not run out yet, which resolves itself.
 */
public record PurgeReport(int purgedBatches, int skippedBatches) {
}
