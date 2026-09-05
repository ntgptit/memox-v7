package com.memox.service;

import java.util.List;

import com.memox.deck.application.CreateRootDeckCommand;
import com.memox.deck.domain.Deck;

public interface DeckService {

	Deck createRootDeck(CreateRootDeckCommand command);

	List<Deck> listRootDecks();
}
