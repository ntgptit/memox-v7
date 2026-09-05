package com.memox.card.api;

import java.util.List;

import com.memox.card.domain.CardPage;

public record CardPageResponse(List<CardResponse> items, int limit, int offset) {

	static CardPageResponse from(CardPage page) {
		return new CardPageResponse(page.items().stream().map(CardResponse::from).toList(), page.limit(), page.offset());
	}
}
