package com.memox.card.service;

import java.time.Clock;
import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.card.entity.Card;
import com.memox.card.enums.CardSortField;
import com.memox.card.persistence.CardMapper;
import com.memox.common.pagination.PageHelper;
import com.memox.common.pagination.PageQuery;
import com.memox.common.pagination.PagingResponse;
import com.memox.common.pagination.SortColumn;
import com.memox.common.pagination.SortDirection;
import com.memox.deck.service.DeckService;
import com.memox.deck.exception.DeckNotFoundException;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Card orchestration.
 *
 * <p>Card faces, examples, hints and pronunciations are the most private content this API holds
 * (BR-51, BR-52). Nothing below logs them: a card is recorded by its id and the deck it landed in,
 * which is what an investigation actually needs.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CardService {

	/** {@code created_at} repeats freely, so the card list needs a unique second key to page safely. */
	private static final SortColumn CARD_TIE_BREAKER = new SortColumn("c.id", SortDirection.ASC);

	private static final List<SortColumn> DEFAULT_CARD_SORT =
			List.of(new SortColumn(CardSortField.CREATED_AT.getColumn(), SortDirection.ASC));

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
		log.info("Created card {} in deck {} on scheduler generation {}",
				card.id(), card.deckId(), scheduler.generation());
		return card;
	}

	@Transactional(readOnly = true)
	public PagingResponse<Card> listCards(String deckId, PageQuery<CardSortField> pageQuery) {
		if (!cardMapper.activeDeckExists(deckId)) {
			throw new DeckNotFoundException(deckId);
		}
		final var slice = PageHelper.slice(pageQuery, DEFAULT_CARD_SORT, CARD_TIE_BREAKER);
		final var cards = cardMapper.findActiveCardsByDeck(deckId, slice);
		final var totalItems = cardMapper.countActiveCardsByDeck(deckId);
		log.debug("Listed {} card(s) of {} in deck {} at page {}",
				cards.size(), totalItems, deckId, pageQuery.getPage());
		return PageHelper.create(pageQuery, cards, totalItems);
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
