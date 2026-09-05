package com.memox.service;

import com.memox.card.application.CreateCardCommand;
import com.memox.card.domain.Card;
import com.memox.common.pagination.PageQuery;
import com.memox.common.pagination.PagingResponse;

public interface CardService {

	Card createCard(CreateCardCommand command);

	PagingResponse<Card> listCards(String deckId, PageQuery pageQuery);
}
