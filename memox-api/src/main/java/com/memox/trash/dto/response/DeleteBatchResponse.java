package com.memox.trash.dto.response;

import java.time.Instant;

import com.memox.trash.entity.DeleteBatch;

/**
 * The batch a soft-delete opened — the handle a restore or an undo acts on (BR-263).
 *
 * <p>It carries no name and no card face: what was deleted is private content on the same footing
 * as anything else in Trash (BR-267), and a client that needs to draw the row reads the Trash list.
 */
public record DeleteBatchResponse(String id, String itemType, String rootItemId, Instant deletedAt) {

	public static DeleteBatchResponse from(DeleteBatch batch) {
		return new DeleteBatchResponse(batch.id(), batch.itemType().getValue(),
				batch.rootItemId(), batch.deletedAt());
	}
}
