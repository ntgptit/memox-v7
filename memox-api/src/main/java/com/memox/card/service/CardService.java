package com.memox.card.service;

import java.time.Clock;
import java.time.Instant;
import java.util.Objects;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.card.domain.Card;
import com.memox.card.domain.CardTextField;
import com.memox.card.persistence.CardMapper;
import com.memox.card.persistence.CardPageQuery;
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
		final var card = new Card(command.id(), command.deckId(), CardTextField.FRONT.normalizeRequired(command.front()),
				CardTextField.BACK.normalizeRequired(command.back()), false,
				CardTextField.EXAMPLE.normalizeOptional(command.example()),
				CardTextField.HINT.normalizeOptional(command.hint()),
				CardTextField.PRONUNCIATION.normalizeOptional(command.pronunciation()), now, now);
		cardMapper.insertCard(card);
		cardMapper.insertInitialStudyState(card.id(), scheduler.schedulerType().getValue(), scheduler.version(),
				scheduler.generation());
		return card;
	}

	@Transactional(readOnly = true)
	public PagingResponse<Card> listCards(String deckId, PageQuery pageQuery) {
		final var pageRows = cardMapper.findActiveCardsByDeck(CardPageQuery.builder()
				.deckId(deckId)
				.page(pageQuery)
				.build());
		if (!pageRows.get(0).isDeckExists()) {
			throw new DeckNotFoundException(deckId);
		}
		final var totalItems = pageRows.get(0).getTotalItems();
		final var cards = pageRows.stream().map(pageRow -> pageRow.getCard()).filter(Objects::nonNull).toList();
		return PageHelper.create(pageQuery, cards, totalItems);
	}
}
