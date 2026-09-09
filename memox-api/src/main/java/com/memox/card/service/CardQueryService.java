package com.memox.card.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.card.entity.CardFilter;
import com.memox.card.entity.CardListItem;
import com.memox.card.entity.CardStateCounts;
import com.memox.card.entity.StageThresholds;
import com.memox.card.enums.CardSortField;
import com.memox.card.persistence.CardMapper;
import com.memox.common.pagination.PageHelper;
import com.memox.common.pagination.PageQuery;
import com.memox.common.pagination.PagingResponse;
import com.memox.common.pagination.SortColumn;
import com.memox.common.pagination.SortDirection;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * The management list: filter, sort, page, and the stage counts beside it.
 *
 * <p>Card faces are the most private content this API holds (BR-51, BR-52), so nothing here logs
 * one — not even the search term, which is a fragment of what someone is looking for.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CardQueryService {

	/**
	 * Newest first, and {@code id} to break ties.
	 *
	 * <p>The default the Flutter list opens with: a card just added is at the top, where the person
	 * who added it is looking (UC-04 A4).
	 */
	private static final List<SortColumn> DEFAULT_SORT =
			List.of(new SortColumn(CardSortField.CREATED_AT.getColumn(), SortDirection.DESC));

	private static final SortColumn TIE_BREAKER = new SortColumn("c.id", SortDirection.DESC);

	private final CardMapper cardMapper;

	@Transactional(readOnly = true)
	public PagingResponse<CardListItem> list(CardFilter filter, PageQuery<CardSortField> pageQuery) {
		final var slice = PageHelper.slice(pageQuery, DEFAULT_SORT, TIE_BREAKER);
		final var items = cardMapper.findCardListItems(filter, slice);
		final var totalItems = cardMapper.countCardListItems(filter);
		log.debug("Listed {} card(s) of {} in deck {} at page {}",
				items.size(), totalItems, filter.deckId(), pageQuery.getPage());
		return PageHelper.create(pageQuery, items, totalItems);
	}

	/**
	 * Every matching id, unpaged — what "select all" in the management list acts on.
	 *
	 * <p>It takes the same {@link PageQuery} so the ids come back in the order the user is looking
	 * at, but the slice's LIMIT and OFFSET are deliberately not applied: selecting all of a filter
	 * means all of it, not the page currently on screen.
	 */
	@Transactional(readOnly = true)
	public List<String> idsMatching(CardFilter filter, PageQuery<CardSortField> pageQuery) {
		final var slice = PageHelper.slice(pageQuery, DEFAULT_SORT, TIE_BREAKER);
		final var ids = cardMapper.findCardIdsMatching(filter, slice);
		log.debug("Matched {} card id(s) in deck {}", ids.size(), filter.deckId());
		return ids;
	}

	@Transactional(readOnly = true)
	public CardStateCounts stateCounts(String deckId, StageThresholds thresholds) {
		return cardMapper.countCardStatesByDeck(deckId, thresholds);
	}
}
