package com.memox.trash.entity;

import java.time.Instant;
import java.util.List;

import com.memox.common.tree.DeckAncestor;
import com.memox.trash.enums.TrashItemType;

/**
 * One row of the Trash list: a deletion, what it took, and where it came from.
 *
 * <p><strong>The counts describe the batch, not the subtree</strong> (BR-262). A descendant already
 * in Trash under an older batch carries that older id, so it is absent from both — which is exactly
 * the number a confirmation has to show, because it is what this restore would bring back.
 *
 * <p><strong>The origin path is information, never a restore target</strong> (BR-267). It crosses
 * tombstones on purpose: the deck a card was deleted from may itself be in Trash today, and "where
 * was this" is still an honest answer. Where it will go back to is a separate, explicit choice
 * (BR-261).
 *
 * <p>{@code itemName} is a deck name or a card's front. It is content — sent to the owner in a
 * response and never written to a log at any level (BR-51, BR-52, BR-267).
 */
public record TrashBatchRow(
		String batchId,
		TrashItemType itemType,
		String rootItemId,
		Instant deletedAt,
		String itemName,
		String originDeckId,
		String originDeckName,
		long batchDeckCount,
		long batchCardCount,
		List<DeckAncestor> originPath) {

	public TrashBatchRow {
		originPath = originPath == null ? List.of() : List.copyOf(originPath);
	}
}
