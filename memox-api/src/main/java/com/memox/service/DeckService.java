package com.memox.service;

import java.util.List;

import com.memox.deck.application.CreateRootDeckCommand;
import com.memox.deck.application.CreateSubDeckCommand;
import com.memox.deck.domain.Deck;

public interface DeckService {

	Deck createRootDeck(CreateRootDeckCommand command);

	Deck createSubDeck(CreateSubDeckCommand command);

	Deck getDeck(String deckId);

	List<Deck> listRootDecks();
}
