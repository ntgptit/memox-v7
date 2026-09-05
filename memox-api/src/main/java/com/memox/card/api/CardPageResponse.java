package com.memox.card.api;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.memox.card.domain.CardPage;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record CardPageResponse(List<CardResponse> items, String nextCursor) {

	static CardPageResponse from(CardPage page) {
		return new CardPageResponse(page.items().stream().map(CardResponse::from).toList(), page.nextCursor());
	}
}
