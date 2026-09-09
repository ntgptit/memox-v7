package com.memox.card.dto.response;

/** How many rows a batch actually wrote — read back, not assumed from the request size. */
public record BulkWriteResponse(int written) {
}
