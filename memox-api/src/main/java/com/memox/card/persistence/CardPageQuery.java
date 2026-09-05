package com.memox.card.persistence;

public record CardPageQuery(String deckId, int limit, int offset) {
}
