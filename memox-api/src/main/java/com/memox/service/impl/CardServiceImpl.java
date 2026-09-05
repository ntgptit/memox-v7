package com.memox.service.impl;

import java.time.Clock;
import java.time.Instant;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.card.application.CreateCardCommand;
import com.memox.card.domain.Card;
import com.memox.card.domain.CardTextField;
import com.memox.card.persistence.CardPageQuery;
import com.memox.card.persistence.CardRow;
import com.memox.common.pagination.PageHelper;
import com.memox.common.pagination.PageQuery;
import com.memox.common.pagination.PagingResponse;
import com.memox.exception.DeckConflictException;
import com.memox.exception.DeckNotFoundException;
import com.memox.exception.DeckValidationException;
import com.memox.deck.domain.DeckContentType;
import com.memox.repository.CardRepository;
import com.memox.repository.DeckRepository;
import com.memox.service.CardService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class CardServiceImpl implements CardService {

	private final CardRepository cardRepository;
	private final DeckRepository deckRepository;
	private final Clock clock;

	@Override
	@Transactional
	public Card createCard(CreateCardCommand command) {
		final var deck = deckRepository.findActiveDeckById(command.deckId());
		if (deck == null) {
			throw new DeckNotFoundException(command.deckId());
		}
		if (deck.getParentDeckId() == null) {
			throw new DeckConflictException("ROOT_CANNOT_HOLD_CARDS", "A root deck cannot contain cards.");
		}
		if (deck.getContentType() == DeckContentType.DECK) {
			throw new DeckConflictException("DECK_HOLDS_CHILDREN", "A deck containing child decks cannot contain cards.");
		}

		final var root = deckRepository.findActiveDeckById(deck.getRootDeckId());
		if (root == null || root.getSchedulerType() == null || root.getSchedulerVersion() == null
				|| root.getSchedulerGeneration() == null) {
			throw new DeckConflictException("ROOT_SCHEDULER_INVALID", "The root deck scheduler is invalid.");
		}

		final var now = Instant.now(clock);
		if (deck.getContentType() == DeckContentType.UNSET) {
			deckRepository.updateContentType(deck.getId(), DeckContentType.CARD, now);
		}

		final var card = CardRow.builder()
				.id(command.id())
				.deckId(deck.getId())
				.front(validateText(command.front(), CardTextField.FRONT))
				.back(validateText(command.back(), CardTextField.BACK))
				.example(normalizeOptional(command.example(), CardTextField.EXAMPLE))
				.hint(normalizeOptional(command.hint(), CardTextField.HINT))
				.pronunciation(normalizeOptional(command.pronunciation(), CardTextField.PRONUNCIATION))
				.createdAt(now)
				.updatedAt(now)
				.build();
		cardRepository.insertCard(card);
		cardRepository.insertInitialStudyState(card.getId(), root.getSchedulerType().getValue(),
				root.getSchedulerVersion(), root.getSchedulerGeneration());

		return card.toDomain();
	}

	@Override
	@Transactional(readOnly = true)
	public PagingResponse<Card> listCards(String deckId, PageQuery pageQuery) {
		if (deckRepository.findActiveDeckById(deckId) == null) {
			throw new DeckNotFoundException(deckId);
		}
		final var query = CardPageQuery.builder().deckId(deckId).page(pageQuery).build();
		final var cards = cardRepository.findActiveCardsByDeck(query).stream().map(CardRow::toDomain).toList();
		final var totalItems = cardRepository.countActiveCardsByDeck(deckId);
		return PageHelper.create(pageQuery, cards, totalItems);
	}

	private String validateText(String rawText, CardTextField field) {
		final var text = rawText.trim();
		if (text.isEmpty()) {
			throw new DeckValidationException(field.getFieldName(), requiredCode(field),
					"Card %s must not be blank.".formatted(field.getFieldName()));
		}
		if (text.length() > field.getMaxLength()) {
			throw new DeckValidationException(field.getFieldName(), tooLongCode(field),
					"Card %s must be at most %d characters.".formatted(field.getFieldName(), field.getMaxLength()));
		}
		return text;
	}

	private String normalizeOptional(String rawText, CardTextField field) {
		if (rawText == null) {
			return null;
		}
		final var text = rawText.trim();
		if (text.isEmpty()) {
			return null;
		}
		if (text.length() > field.getMaxLength()) {
			throw new DeckValidationException(field.getFieldName(), tooLongCode(field),
					"Card %s must be at most %d characters.".formatted(field.getFieldName(), field.getMaxLength()));
		}
		return text;
	}

	private String requiredCode(CardTextField field) {
		return "CARD_%s_REQUIRED".formatted(field.name());
	}

	private String tooLongCode(CardTextField field) {
		return "CARD_%s_TOO_LONG".formatted(field.name());
	}

}
