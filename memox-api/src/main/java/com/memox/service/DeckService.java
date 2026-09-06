package com.memox.service;

import com.memox.common.pagination.PageQuery;
import com.memox.common.pagination.PagingResponse;
import com.memox.deck.application.CreateRootDeckCommand;
import com.memox.deck.application.CreateSubDeckCommand;
import com.memox.deck.domain.Deck;

public interface DeckService {

	Deck createRootDeck(CreateRootDeckCommand command);

	Deck createSubDeck(CreateSubDeckCommand command);

	Deck getDeck(String deckId);

	PagingResponse<Deck> listRootDecks(PageQuery pageQuery);
}
