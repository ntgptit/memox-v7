package com.memox.deck.service;

import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.common.pagination.PageHelper;
import com.memox.common.pagination.PageQuery;
import com.memox.common.pagination.PagingResponse;
import com.memox.common.pagination.SortColumn;
import com.memox.common.pagination.SortDirection;
import com.memox.deck.entity.Deck;
import com.memox.deck.entity.DeckContext;
import com.memox.deck.entity.DeckLevel;
import com.memox.deck.entity.DeckLevelChild;
import com.memox.deck.entity.DeckLevelRow;
import com.memox.deck.entity.DeckSummary;
import com.memox.deck.enums.DeckSortField;
import com.memox.deck.persistence.DeckMapper;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * The three deck reads the Library screen and the deck picker are built on.
 *
 * <p>Deck names are user content, so nothing here logs one (BR-51, BR-267). The debug lines carry
 * ids and counts, which is what an investigation needs anyway.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DeckTreeService {

	private static final SortColumn TIE_BREAKER = new SortColumn("id", SortDirection.ASC);

	private static final List<SortColumn> DEFAULT_SORT =
			List.of(new SortColumn(DeckSortField.SIBLING_POSITION.getColumn(), SortDirection.ASC));

	private final DeckMapper deckMapper;

	/**
	 * One page of root decks with their aggregate counts.
	 *
	 * <p>The two instants belong to the caller, not to the server: {@code startOfToday} decides what
	 * counts as overdue, and that boundary is a fact about the user's day (BR-105).
	 */
	@Transactional(readOnly = true)
	public PagingResponse<DeckSummary> listRootSummaries(
			PageQuery<DeckSortField> pageQuery, Instant now, Instant startOfToday) {
		final var slice = PageHelper.slice(pageQuery, DEFAULT_SORT, TIE_BREAKER);
		final var summaries = deckMapper.findRootDeckSummaries(slice, now, startOfToday);
		final var totalItems = deckMapper.countRootDecks();
		log.debug("Summarised {} root deck(s) of {} at page {}",
				summaries.size(), totalItems, pageQuery.getPage());
		return PageHelper.create(pageQuery, summaries, totalItems);
	}

	/**
	 * One root's whole tree, the root included, at any depth.
	 *
	 * <p>No recursion is needed and none is used: every descendant already carries its
	 * {@code root_deck_id} (BR-56).
	 */
	@Transactional(readOnly = true)
	public List<Deck> listTree(String rootDeckId) {
		final var decks = deckMapper.findDecksInTree(rootDeckId);
		log.debug("Read {} deck(s) in tree {}", decks.size(), rootDeckId);
		return decks;
	}

	/**
	 * One deck opened: its header, its breadcrumb and its direct children with subtree counts.
	 *
	 * <p>The statement returns one row per child, and one row with no child when the deck is empty,
	 * because the join to children is a LEFT JOIN. Folding happens here rather than in the result
	 * map: the header repeats on every row and a childless deck must produce an empty list, not a
	 * child made of nulls.
	 *
	 * @return null when the deck does not exist or is in Trash — the same thing every write path in
	 *         this module turns a missing row into (BR-257)
	 */
	@Transactional(readOnly = true)
	public DeckLevel readLevel(String deckId, Instant now, Instant startOfToday) {
		final var rows = deckMapper.findChildDeckLevel(deckId, now, startOfToday, DeckLimits.MAX_WALK);
		if (rows.isEmpty()) {
			return null;
		}
		final var header = rows.get(0);
		final var children = rows.stream().filter(DeckLevelRow::hasChild).map(this::toChild).toList();
		log.debug("Read level of deck {} with {} child/children", deckId, children.size());
		return new DeckLevel(
				new DeckContext(header.parentId(), header.parentName(), header.parentContentType(),
						header.ancestry()),
				children,
				header.nextDueAt());
	}

	/**
	 * A deck's own name and the path above it, for the card list header.
	 *
	 * @return null when the deck does not exist or is in Trash
	 */
	@Transactional(readOnly = true)
	public DeckContext readContext(String deckId) {
		return deckMapper.findDeckContext(deckId, DeckLimits.MAX_WALK);
	}

	private DeckLevelChild toChild(DeckLevelRow row) {
		final var child = new Deck(row.childId(), row.childName(), row.childParentDeckId(),
				row.childRootDeckId(), row.childContentType(), null, null, null,
				row.childSiblingPosition(), row.childCreatedAt(), row.childUpdatedAt());
		return new DeckLevelChild(child, row.inheritedSchedulerType(), row.totalCardCount(),
				row.newCardCount(), row.dueCardCount(), row.overdueCardCount(), row.oldestDueAt(),
				row.learnedCardCount(), row.subDeckCount());
	}

	/**
	 * Every active deck, for the move-target picker.
	 *
	 * <p>One statement rather than one per tree. The picker has to offer every tree by definition,
	 * so calling {@link #listTree} in a loop would be N+1 in the number of trees, and the number of
	 * trees is exactly what grows.
	 */
	@Transactional(readOnly = true)
	public List<Deck> listAllActive() {
		final var decks = deckMapper.findAllActiveDecks();
		log.debug("Read {} active deck(s)", decks.size());
		return decks;
	}
}
