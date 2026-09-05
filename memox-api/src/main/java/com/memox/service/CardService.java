package com.memox.service;

import com.memox.card.application.CreateCardCommand;
import com.memox.card.domain.Card;

public interface CardService {

	Card createCard(CreateCardCommand command);
}
