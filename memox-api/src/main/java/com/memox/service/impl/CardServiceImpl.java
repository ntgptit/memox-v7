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
import com.memox.exception.ApiErrorCode;
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
		final var deck = deckRepository.findActiveDeckByIdForUpdate(command.deckId());
		if (deck == null) {
			throw new DeckNotFoundException(command.deckId());
		}
		if (deck.getParentDeckId() == null) {
			throw new DeckConflictException(ApiErrorCode.ROOT_CANNOT_HOLD_CARDS);
		}
		if (deck.getContentType() == DeckContentType.DECK) {
			throw new DeckConflictException(ApiErrorCode.DECK_HOLDS_CHILDREN);
		}

		final var root = deckRepository.findActiveDeckById(deck.getRootDeckId());
		if (root == null || root.getSchedulerType() == null || root.getSchedulerVersion() == null
				|| root.getSchedulerGeneration() == null) {
			throw new DeckConflictException(ApiErrorCode.ROOT_SCHEDULER_INVALID);
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
			throw new DeckValidationException(field.getFieldName(), requiredCode(field));
		}
		if (text.length() > field.getMaxLength()) {
			throw new DeckValidationException(field.getFieldName(), tooLongCode(field));
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
			throw new DeckValidationException(field.getFieldName(), tooLongCode(field));
		}
		return text;
	}

	private ApiErrorCode requiredCode(CardTextField field) {
		return switch (field) {
			case FRONT -> ApiErrorCode.CARD_FRONT_REQUIRED;
			case BACK -> ApiErrorCode.CARD_BACK_REQUIRED;
			case EXAMPLE, HINT, PRONUNCIATION -> throw new IllegalArgumentException(
					"Optional card fields cannot require a value.");
		};
	}

	private ApiErrorCode tooLongCode(CardTextField field) {
		return switch (field) {
			case FRONT -> ApiErrorCode.CARD_FRONT_TOO_LONG;
			case BACK -> ApiErrorCode.CARD_BACK_TOO_LONG;
			case EXAMPLE -> ApiErrorCode.CARD_EXAMPLE_TOO_LONG;
			case HINT -> ApiErrorCode.CARD_HINT_TOO_LONG;
			case PRONUNCIATION -> ApiErrorCode.CARD_PRONUNCIATION_TOO_LONG;
		};
	}

}
