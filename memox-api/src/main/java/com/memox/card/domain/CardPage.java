package com.memox.card.domain;

import java.util.List;

public record CardPage(List<Card> items, String nextCursor) {
}
