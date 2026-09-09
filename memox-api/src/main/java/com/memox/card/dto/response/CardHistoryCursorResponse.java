package com.memox.card.dto.response;

import java.time.Instant;

/** Hand this straight back as the next request's cursor; both halves are required. */
public record CardHistoryCursorResponse(Instant answeredAt, String id) {
}
