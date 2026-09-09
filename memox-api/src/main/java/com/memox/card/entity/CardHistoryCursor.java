package com.memox.card.entity;

import java.time.Instant;

/**
 * Where the previous page of history ended.
 *
 * <p>Both parts are needed. Two turns of one session can share a millisecond, so
 * {@code answered_at} alone is not a total order and a page boundary falling inside a group of
 * equal timestamps either loses rows or repeats them.
 *
 * <p>The next page starts <strong>strictly</strong> after this row. Including it again is the
 * duplicate BR-241 forbids.
 */
public record CardHistoryCursor(Instant answeredAt, String id) {
}
