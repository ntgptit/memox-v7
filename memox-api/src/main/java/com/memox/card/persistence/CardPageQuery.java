package com.memox.card.persistence;

import com.memox.common.pagination.PageQuery;

import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class CardPageQuery {

	String deckId;
	PageQuery page;
}
