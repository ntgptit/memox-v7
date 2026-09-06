package com.memox.card.service;

import java.time.Clock;
import java.time.Instant;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.card.domain.Card;
import com.memox.card.persistence.CardMapper;
import com.memox.common.pagination.PageHelper;
import com.memox.common.pagination.PageQuery;
import com.memox.common.pagination.PagingResponse;
import com.memox.deck.service.DeckService;
import com.memox.deck.domain.DeckNotFoundException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class CardService {

	private final CardMapper cardMapper;
	private final DeckService deckService;
	private final Clock clock;

	@Transactional
	public Card createCard(CreateCardCommand command) {
		final var scheduler = deckService.prepareCardCreation(command.deckId());
		final var now = Instant.now(clock);
		final var card = new Card(command.id(), command.deckId(), normalizeRequired(command.front()),
				normalizeRequired(command.back()), false, normalizeOptional(command.example()), normalizeOptional(command.hint()),
				normalizeOptional(command.pronunciation()), now, now);
		cardMapper.insertCard(card);
		cardMapper.insertInitialStudyState(card.id(), scheduler.schedulerType().getValue(), scheduler.version(),
				scheduler.generation());
		return card;
	}

	@Transactional(readOnly = true)
	public PagingResponse<Card> listCards(String deckId, PageQuery pageQuery) {
		if (!cardMapper.activeDeckExists(deckId)) {
			throw new DeckNotFoundException(deckId);
		}
		return PageHelper.create(pageQuery, cardMapper.findActiveCardsByDeck(deckId, pageQuery),
				cardMapper.countActiveCardsByDeck(deckId));
	}

	private String normalizeRequired(String value) {
		return value.trim();
	}

	private String normalizeOptional(String value) {
		if (value == null) {
			return null;
		}
		final var normalizedValue = value.trim();
		if (normalizedValue.isEmpty()) {
			return null;
		}
		return normalizedValue;
	}
}
