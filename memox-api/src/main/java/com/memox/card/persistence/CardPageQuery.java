package com.memox.card.persistence;

import java.time.Instant;

public record CardPageQuery(String deckId, Instant afterCreatedAt, String afterId, int limit) {
}
