package com.memox.trash.dto.response;

import java.time.Instant;
import java.util.List;

import com.memox.trash.entity.TrashBatchRow;

/**
 * One row of the Trash screen.
 *
 * <p>{@code originPath} is where the item was, and it is <strong>information only</strong>
 * (BR-267): a client must not present it as the place a restore will put the item back, because
 * BR-261 makes that an explicit choice and the old parent may itself be in Trash by now.
 *
 * <p>The two counts are what <em>this</em> restore would bring back, not the size of the subtree.
 */
public record TrashBatchResponse(
		String batchId,
		String itemType,
		String rootItemId,
		Instant deletedAt,
		String itemName,
		String originDeckId,
		String originDeckName,
		long batchDeckCount,
		long batchCardCount,
		List<TrashOriginStepResponse> originPath) {

	public TrashBatchResponse {
		originPath = List.copyOf(originPath);
	}

	public static TrashBatchResponse from(TrashBatchRow row) {
		return new TrashBatchResponse(row.batchId(), row.itemType().getValue(), row.rootItemId(),
				row.deletedAt(), row.itemName(), row.originDeckId(), row.originDeckName(),
				row.batchDeckCount(), row.batchCardCount(),
				row.originPath().stream().map(TrashOriginStepResponse::from).toList());
	}
}
