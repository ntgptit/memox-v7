package com.memox.card.service;

import java.time.Clock;
import java.time.Instant;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.card.entity.Card;
import com.memox.card.exception.CardNotFoundException;
import com.memox.card.persistence.CardMapper;
import com.memox.common.persistence.AffectedRows;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Editing one card's content.
 *
 * <p>BR-92: content only. The flag is not content and the schedule is not content — an edit that
 * touched either would silently undo a review or a deliberate flag, and content is the one thing
 * that survives every scheduler reset.
 *
 * <p>Nothing here logs a face, an example, a hint or a pronunciation (BR-51, BR-52). The log line
 * carries the card id, which is what an investigation needs.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CardEditService {

	private final CardMapper cardMapper;
	private final Clock clock;

	/**
	 * Rewrites one card's content and its folded search columns together.
	 *
	 * <p>Optional fields are normalised exactly the way creation normalises them — trimmed, and
	 * blank becomes absent — so an edit cannot leave a card in a shape a create could not produce.
	 *
	 * @throws CardNotFoundException when the card does not exist or is in Trash (BR-245, BR-257)
	 */
	@Transactional
	public Card update(UpdateCardCommand command) {
		final var now = Instant.now(clock);
		final var content = new Card(command.cardId(), null,
				normalizeRequired(command.front()), normalizeRequired(command.back()), false,
				normalizeOptional(command.example()), normalizeOptional(command.hint()),
				normalizeOptional(command.pronunciation()), null, now);

		AffectedRows.requireExactlyOne(
				cardMapper.updateCardContent(content),
				() -> new CardNotFoundException(command.cardId()));
		log.info("Edited the content of card {}", command.cardId());
		return cardMapper.findCardById(command.cardId());
	}

	private String normalizeRequired(String value) {
		return value.trim();
	}

	private String normalizeOptional(String value) {
		if (value == null) {
			return null;
		}
		final var normalized = value.trim();
		if (normalized.isEmpty()) {
			return null;
		}
		return normalized;
	}
}
