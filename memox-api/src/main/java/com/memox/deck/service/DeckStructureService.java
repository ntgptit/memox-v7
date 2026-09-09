package com.memox.deck.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.deck.persistence.DeckMapper;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * The structural questions the deck rules ask before they allow a write.
 *
 * <p>Each one is a single recursive statement. The version this replaces walked the tree with up to
 * ten separate SELECTs <em>inside the write transaction</em>, so the depth check held its locks for
 * as long as the tree was deep and cost a round trip per level.
 *
 * <p>Every probe reads active rows only. A deck in Trash is invisible to these questions for the
 * same reason it is invisible to every other read path (BR-257) — a subtree that includes a
 * tombstoned branch would move or delete rows the user believes are already gone.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DeckStructureService {

	/** What a probe answers for a deck that does not exist or is in Trash. */
	private static final int NO_DECK = 0;

	private final DeckMapper deckMapper;

	/**
	 * How deep a deck sits, counting the root as 1 (BR-55).
	 *
	 * @return 0 when the deck does not exist or is in Trash; otherwise the depth, capped at
	 *         {@link DeckLimits#MAX_WALK}
	 */
	@Transactional(readOnly = true)
	public int depthOf(String deckId) {
		final var depth = deckMapper.probeDeckDepth(deckId, DeckLimits.MAX_WALK);
		if (depth == null) {
			return NO_DECK;
		}
		if (!depth.reachedRoot()) {
			// Only corrupt data reaches here: BR-55 caps a real tree at ten. The number is a lower
			// bound rather than a measurement, which is safe for the depth rule — it is already
			// above the limit and will refuse the write — but it means this tree needs looking at.
			log.warn("Deck {} has no reachable root within {} levels; its ancestry is cyclic or corrupt",
					deckId, DeckLimits.MAX_WALK);
		}
		return depth.depth();
	}

	/**
	 * How many levels the subtree rooted at this deck spans, the deck itself counting as 1.
	 *
	 * <p>Depth and height together are what a move has to check: the target's depth plus the moved
	 * subtree's height must still fit under the ceiling (BR-55).
	 */
	@Transactional(readOnly = true)
	public int subtreeHeight(String deckId) {
		final var height = deckMapper.probeSubtreeHeight(deckId, DeckLimits.MAX_WALK);
		if (height == null) {
			return NO_DECK;
		}
		return height;
	}

	/** Every deck in the subtree, the deck itself included, because a move or delete acts on all. */
	@Transactional(readOnly = true)
	public List<String> subtreeDeckIds(String deckId) {
		return deckMapper.findSubtreeDeckIds(deckId);
	}

	@Transactional(readOnly = true)
	public long directChildDeckCount(String deckId) {
		return deckMapper.countDirectChildDecks(deckId);
	}

	@Transactional(readOnly = true)
	public long directCardCount(String deckId) {
		return deckMapper.countDirectCards(deckId);
	}

	@Transactional(readOnly = true)
	public long subtreeCardCount(String deckId) {
		return deckMapper.countSubtreeCards(deckId);
	}
}
