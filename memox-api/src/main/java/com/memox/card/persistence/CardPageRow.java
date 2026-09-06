package com.memox.card.persistence;

import com.memox.card.domain.Card;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class CardPageRow {

	private Card card;
	private long totalItems;
	private boolean deckExists;
}
