package com.memox.trash.exception;

import com.memox.common.error.ApiErrorCode;
import com.memox.common.error.MemoxException;

import lombok.Getter;

/**
 * A delete batch that is no longer in Trash.
 *
 * <p>Restored by someone else, purged by retention, or never there. All three are the same answer
 * to the caller: the item they are looking at is gone from Trash.
 */
@Getter
public class TrashNotFoundException extends MemoxException {

	private static final long serialVersionUID = 2411885246971153080L;

	private final String batchId;

	public TrashNotFoundException(String batchId) {
		super(ApiErrorCode.BATCH_NOT_FOUND, "batchId=" + batchId);
		this.batchId = batchId;
	}
}
