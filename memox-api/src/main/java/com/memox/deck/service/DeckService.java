package com.memox.deck.service;

import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.common.pagination.PageHelper;
import com.memox.common.pagination.PageQuery;
import com.memox.common.pagination.PagingResponse;
import com.memox.common.pagination.SortColumn;
import com.memox.common.pagination.SortDirection;
import com.memox.common.persistence.AffectedRows;
import com.memox.deck.entity.Deck;
import com.memox.deck.enums.DeckContentType;
import com.memox.deck.enums.DeckSortField;
import com.memox.deck.entity.DeckSchedulerState;
import com.memox.deck.persistence.DeckMapper;
import com.memox.deck.persistence.DeckPositionScope;
import com.memox.common.error.ApiErrorCode;
import com.memox.deck.exception.DeckConflictException;
import com.memox.deck.exception.DeckNotFoundException;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Deck orchestration and the transactions the deck rules need.
 *
 * <p>The logs here record ids, counts and state transitions only. Deck names are user content and
 * BR-51/BR-52/BR-267 forbid them at every level, which is why {@code deck.name()} appears nowhere
 * below and why Checkstyle's {@code noPrivateContentInLogs} rule watches for it.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DeckService {

	private static final int INITIAL_SCHEDULER_VERSION = 1;
	private static final int INITIAL_SCHEDULER_GENERATION = 1;

	/**
	 * The tie-breaker every deck page carries.
	 *
	 * <p>{@code sibling_position} is unique only within one parent, and the root list spans all of
	 * them; without a unique second key, two pages of the same list can repeat a deck and drop
	 * another, because nothing obliges PostgreSQL to break a tie the same way twice.
	 */
	private static final SortColumn DECK_TIE_BREAKER = new SortColumn("id", SortDirection.ASC);

	private static final List<SortColumn> DEFAULT_DECK_SORT =
			List.of(new SortColumn(DeckSortField.SIBLING_POSITION.getColumn(), SortDirection.ASC));

	private final DeckMapper deckMapper;
	private final DeckStructureService deckStructureService;
	private final Clock clock;

	@Transactional
	public Deck createRootDeck(CreateRootDeckCommand command) {
		deckMapper.lockRootDeckCreation();

		final var now = Instant.now(clock);
		final var deck = new Deck(command.id(), normalizeName(command.name()), null, command.id(),
				DeckContentType.DECK, command.schedulerType(), INITIAL_SCHEDULER_VERSION,
				INITIAL_SCHEDULER_GENERATION, deckMapper.nextSiblingPosition(DeckPositionScope.ROOT_DECKS), now, now);
		deckMapper.insertRootDeck(deck);
		log.info("Created root deck {} with scheduler {} generation {}",
				deck.id(), deck.schedulerType(), deck.schedulerGeneration());
		return deck;
	}

	@Transactional
	public Deck createSubDeck(CreateSubDeckCommand command) {
		final var parent = requireActiveDeckForUpdate(command.parentDeckId());
		if (parent.contentType() == DeckContentType.CARD) {
			throw new DeckConflictException(ApiErrorCode.PARENT_HOLDS_CARDS, parent.id());
		}
		// One recursive statement, not a loop of up to ten SELECTs inside this write transaction.
		if (deckStructureService.depthOf(parent.id()) >= DeckLimits.MAX_TREE_DEPTH) {
			throw new DeckConflictException(ApiErrorCode.DECK_DEPTH_EXCEEDED, parent.id());
		}

		final var now = Instant.now(clock);
		if (parent.contentType() == DeckContentType.UNSET) {
			AffectedRows.requireExactlyOne(
					deckMapper.updateContentType(parent.id(), DeckContentType.DECK, now),
					() -> new IllegalStateException("locked parent deck vanished mid-transaction: " + parent.id()));
			log.info("Deck {} now holds sub-decks", parent.id());
		}

		final var deck = new Deck(command.id(), normalizeName(command.name()), parent.id(), parent.rootDeckId(),
				DeckContentType.UNSET, null, null, null, deckMapper.nextSiblingPosition(parent.id()), now, now);
		deckMapper.insertSubDeck(deck);
		log.info("Created sub deck {} under {} in root {}", deck.id(), parent.id(), deck.rootDeckId());
		return deck;
	}

	@Transactional(readOnly = true)
	public PagingResponse<Deck> listRootDecks(PageQuery<DeckSortField> pageQuery) {
		final var slice = PageHelper.slice(pageQuery, DEFAULT_DECK_SORT, DECK_TIE_BREAKER);
		final var decks = deckMapper.findRootDecks(slice);
		final var totalItems = deckMapper.countRootDecks();
		log.debug("Listed {} root deck(s) of {} at page {} size {}",
				decks.size(), totalItems, pageQuery.getPage(), pageQuery.getSize());
		return PageHelper.create(pageQuery, decks, totalItems);
	}

	@Transactional(readOnly = true)
	public Deck getDeck(String deckId) {
		return requireActiveDeck(deckId);
	}

	/**
	 * Moves a deck to a new place among its siblings and returns the group in its new order.
	 *
	 * <p><strong>The reorder permutes the positions the active siblings already own; it does not
	 * renumber them densely from zero.</strong> That distinction is the whole design. A
	 * soft-deleted sibling keeps its {@code sibling_position} row, so it still holds a slot in
	 * {@code uq_decks_sibling_scope_position} while holding no place in the order a user sees
	 * (BR-257). Renumbering from zero would walk an active deck straight onto a tombstone's slot,
	 * and that collision survives to COMMIT — a deferred constraint makes a <em>transient</em>
	 * conflict legal, not a final one. Permuting the owned set leaves every tombstone where it is.
	 *
	 * <p>The deferred constraint is still required, and this is where: reaching the new arrangement
	 * means passing through states where two siblings share a position, because the writes happen
	 * one row at a time.
	 *
	 * @param command target position is an index among ACTIVE siblings, not a raw column value
	 * @return the active sibling group in its new order
	 */
	@Transactional
	public List<Deck> reorderDeck(ReorderDeckCommand command) {
		final var deck = requireActiveDeckForUpdate(command.deckId());
		final var siblings = deckMapper.findSiblingDecksForUpdate(siblingScopeOf(deck));
		final var current = indexOf(siblings, deck.id());
		if (current < 0) {
			throw new IllegalStateException(
					"locked deck is absent from its own sibling group: " + deck.id());
		}
		if (command.targetPosition() < DeckLimits.MIN_SIBLING_POSITION
				|| command.targetPosition() >= siblings.size()) {
			throw new DeckConflictException(ApiErrorCode.DECK_POSITION_OUT_OF_RANGE, deck.id());
		}

		final var reordered = new ArrayList<>(siblings);
		reordered.add(command.targetPosition(), reordered.remove(current));
		final var ownedPositions = siblings.stream().map(Deck::siblingPosition).sorted().toList();
		final var now = Instant.now(clock);
		return writePositions(reordered, ownedPositions, now);
	}

	@Transactional
	public DeckSchedulerState prepareCardCreation(String deckId) {
		final var deck = requireActiveDeckForUpdate(deckId);
		if (deck.parentDeckId() == null) {
			throw new DeckConflictException(ApiErrorCode.ROOT_CANNOT_HOLD_CARDS, deck.id());
		}
		if (deck.contentType() == DeckContentType.DECK) {
			throw new DeckConflictException(ApiErrorCode.DECK_HOLDS_CHILDREN, deck.id());
		}

		final var root = requireActiveDeck(deck.rootDeckId());
		if (root.schedulerType() == null || root.schedulerVersion() == null || root.schedulerGeneration() == null) {
			throw new DeckConflictException(ApiErrorCode.ROOT_SCHEDULER_INVALID, root.id());
		}
		if (deck.contentType() == DeckContentType.UNSET) {
			AffectedRows.requireExactlyOne(
					deckMapper.updateContentType(deck.id(), DeckContentType.CARD, Instant.now(clock)),
					() -> new IllegalStateException("locked deck vanished mid-transaction: " + deck.id()));
			log.info("Deck {} now holds cards", deck.id());
		}
		return new DeckSchedulerState(root.schedulerType(), root.schedulerVersion(), root.schedulerGeneration());
	}

	private Deck requireActiveDeck(String deckId) {
		final var deck = deckMapper.findActiveDeckById(deckId);
		if (deck == null) {
			throw new DeckNotFoundException(deckId);
		}
		return deck;
	}

	private Deck requireActiveDeckForUpdate(String deckId) {
		final var deck = deckMapper.findActiveDeckByIdForUpdate(deckId);
		if (deck == null) {
			throw new DeckNotFoundException(deckId);
		}
		return deck;
	}

	/**
	 * Writes each sibling its new position and returns the group as it now stands.
	 *
	 * <p>The returned decks are rebuilt from the written values rather than re-read. A second SELECT
	 * would be a second snapshot, and the caller would be shown a group assembled from two moments.
	 */
	private List<Deck> writePositions(List<Deck> reordered, List<Integer> ownedPositions, Instant now) {
		final var written = new ArrayList<Deck>(reordered.size());
		for (int index = 0; index < reordered.size(); index++) {
			final var sibling = reordered.get(index);
			final int position = ownedPositions.get(index);
			AffectedRows.requireExactlyOne(
					deckMapper.updateSiblingPosition(sibling.id(), position, now),
					() -> new IllegalStateException("locked sibling vanished mid-reorder: " + sibling.id()));
			written.add(new Deck(sibling.id(), sibling.name(), sibling.parentDeckId(), sibling.rootDeckId(),
					sibling.contentType(), sibling.schedulerType(), sibling.schedulerVersion(),
					sibling.schedulerGeneration(), position, sibling.createdAt(), now));
		}
		log.info("Reordered {} sibling deck(s) in scope {}", written.size(), siblingScopeOf(written.get(0)));
		return written;
	}

	/** Roots share one scope because a root has no parent to scope it by. */
	private String siblingScopeOf(Deck deck) {
		if (deck.parentDeckId() == null) {
			return DeckPositionScope.ROOT_DECKS;
		}
		return deck.parentDeckId();
	}

	private int indexOf(List<Deck> siblings, String deckId) {
		for (int index = 0; index < siblings.size(); index++) {
			if (siblings.get(index).id().equals(deckId)) {
				return index;
			}
		}
		return -1;
	}

	private String normalizeName(String name) {
		return name.trim();
	}
}
