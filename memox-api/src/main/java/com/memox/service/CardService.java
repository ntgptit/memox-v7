package com.memox.service;

import com.memox.card.application.CreateCardCommand;
import com.memox.card.domain.Card;
import com.memox.card.domain.CardPage;

public interface CardService {

	Card createCard(CreateCardCommand command);

	CardPage listCards(String deckId, int limit, String afterCursor);
}
