package com.memox.deck.persistence;

import com.memox.deck.domain.Deck;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class DeckPageRow {

	private Deck deck;
	private long totalItems;
}
