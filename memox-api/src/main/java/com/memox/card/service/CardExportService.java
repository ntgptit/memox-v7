package com.memox.card.service;

import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.card.entity.CardKey;
import com.memox.card.entity.DeckExport;
import com.memox.card.entity.ExportCard;
import com.memox.card.exception.CardConflictException;
import com.memox.card.persistence.CardMapper;
import com.memox.common.error.ApiErrorCode;
import com.memox.common.persistence.IdCollections;
import com.memox.deck.exception.DeckNotFoundException;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * The data an export is made of, and the duplicate probe an import runs against a deck.
 *
 * <p>The server exposes the data; the file is the client's. Three things follow from that and each
 * is a rule rather than a preference. BR-176 puts the {@code ;}-with-escapes tag codec in one place
 * shared by import and export, so the tags travel as a list and are joined there. BR-180 builds the
 * file name from the deck name, a sanitiser and a date from the client's own clock. And BR-179's
 * six lowercase headers are a property of the file, which nothing here writes.
 *
 * <p>Every method is read-only (BR-178): an export must not touch content, {@code updated_at}, the
 * deck's content type, a study state, a session, a flag or a tag link.
 *
 * <p>Nothing here logs a card face, a tag or the deck name (BR-51, BR-52, BR-173, BR-267) — counts
 * and ids only.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CardExportService {

	private static final String CARD_IDS = "cardIds";

	private final CardMapper cardMapper;

	/**
	 * Scope {@code all}: every card held <em>directly</em> by the deck (BR-174).
	 *
	 * @throws DeckNotFoundException when the deck does not exist or is in Trash
	 * @throws CardConflictException when the deck holds no active card — BR-174 refuses an empty
	 *     scope in the repository even when the UI has already hidden the action, because a deck
	 *     whose last card was deleted from another screen arrives here with the button still up
	 */
	@Transactional(readOnly = true)
	public DeckExport exportDeck(String deckId) {
		final var deckName = requireDeckName(deckId);
		final var cards = cardMapper.findExportCardsInDeck(deckId);
		requireNonEmptyScope(deckId, cards);
		log.info("Exported {} card(s) of deck {}", cards.size(), deckId);
		return new DeckExport(deckName, cards);
	}

	/**
	 * Scope {@code selected}: exactly the ids asked for, or nothing at all (BR-174).
	 *
	 * <p><strong>Which ids came back, not how many.</strong> Duplicates are normalised away first, so
	 * a short result and a stale id look identical to a count; subtracting the returned ids from the
	 * requested ones names the difference instead. A card that was deleted and a card that moved to
	 * another deck both simply fail to return, because the statement filters on the deck as well as
	 * on the id — one subtraction covers both halves of the rule.
	 *
	 * @throws DeckNotFoundException when the deck does not exist or is in Trash
	 * @throws CardConflictException when any requested id did not come back
	 */
	@Transactional(readOnly = true)
	public DeckExport exportCards(String deckId, Collection<String> cardIds) {
		final var requested = new LinkedHashSet<>(IdCollections.requireUsableBatch(cardIds, CARD_IDS));
		final var deckName = requireDeckName(deckId);
		final var cards = cardMapper.findExportCardsByIds(deckId, requested);
		requireEveryRequestedCard(requested, cards);
		log.info("Exported {} selected card(s) of deck {}", cards.size(), deckId);
		return new DeckExport(deckName, cards);
	}

	/**
	 * The duplicate identities already in one deck (BR-170).
	 *
	 * <p>Not refused for an empty deck: "this deck has no duplicates" is an answer, and the import
	 * preview asks the question before the user has committed to anything.
	 */
	@Transactional(readOnly = true)
	public Set<CardKey> existingKeys(String deckId) {
		requireDeckName(deckId);
		final var keys = Set.copyOf(cardMapper.findCardKeysInDeck(deckId));
		log.debug("Probed {} duplicate key(s) in deck {}", keys.size(), deckId);
		return keys;
	}

	/**
	 * The deck's name, read in the same transaction as the cards so both are one snapshot (BR-177).
	 *
	 * <p>The name is never logged: it is user content on the same footing as a card face, and BR-173
	 * extends that to the file name derived from it.
	 */
	private String requireDeckName(String deckId) {
		final var deckName = cardMapper.findExportDeckName(deckId);
		if (deckName == null) {
			throw new DeckNotFoundException(deckId);
		}
		return deckName;
	}

	private void requireNonEmptyScope(String deckId, List<ExportCard> cards) {
		if (!cards.isEmpty()) {
			return;
		}
		throw new CardConflictException(ApiErrorCode.EXPORT_SCOPE_EMPTY, deckId);
	}

	private void requireEveryRequestedCard(Set<String> requested, List<ExportCard> cards) {
		final var returned = cards.stream().map(ExportCard::cardId).collect(Collectors.toSet());
		final var missing = requested.stream().filter(id -> !returned.contains(id)).findFirst();
		if (missing.isEmpty()) {
			return;
		}
		throw new CardConflictException(ApiErrorCode.EXPORT_SELECTION_STALE, missing.get());
	}
}
