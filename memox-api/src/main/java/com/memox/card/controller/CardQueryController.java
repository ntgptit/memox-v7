package com.memox.card.controller;

import java.util.List;

import org.springdoc.core.annotations.ParameterObject;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.memox.card.dto.request.CardFilterRequest;
import com.memox.card.dto.request.CardHistoryRequest;
import com.memox.card.dto.request.CardPageRequest;
import com.memox.card.dto.response.CardHistoryResponse;
import com.memox.card.dto.response.CardListResponse;
import com.memox.card.dto.response.CardStateCountsResponse;
import com.memox.card.entity.StageThresholds;
import com.memox.card.service.CardQueryService;
import com.memox.common.config.PaginationProperties;
import com.memox.common.pagination.PagingResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

/**
 * The management list, which spans decks rather than living under one.
 *
 * <p>Separate from {@code CardController} because the resource is different: that one is a deck's
 * cards, this one is cards filtered by anything — deck, subtree, flag, tags, text — and the deck is
 * one optional filter among several.
 *
 * <p>{@code /ids} and {@code /state-counts} are literal segments beside {@code /{cardId}} paths that
 * later tasks add. Spring matches a literal before a pattern, and card ids are validated UUIDs, so
 * neither can be shadowed.
 */
@RestController
@RequestMapping("/api/v1/cards")
@RequiredArgsConstructor
@Tag(name = "Cards")
public class CardQueryController {

	private final CardQueryService cardQueryService;
	private final PaginationProperties paginationProperties;

	@GetMapping
	@Operation(summary = "List cards by deck, subtree, flag, tags and text")
	@ApiResponses({
			@ApiResponse(responseCode = "200", description = "Card page returned"),
			@ApiResponse(responseCode = "400", description = "Invalid pagination or sort parameters")
	})
	public PagingResponse<CardListResponse> list(
			@Valid @ParameterObject CardFilterRequest filter,
			@Valid @ParameterObject CardPageRequest page) {
		return cardQueryService.list(filter.toFilter(), toPageQuery(page)).map(CardListResponse::from);
	}

	/**
	 * Every matching id, unpaged — what "select all" acts on.
	 *
	 * <p>It takes the same sort so the ids arrive in the order on screen, but no page window:
	 * selecting all of a filter means all of it, not the page being looked at.
	 */
	@GetMapping("/ids")
	@Operation(summary = "Every card id matching the filter, unpaged")
	@ApiResponses(@ApiResponse(responseCode = "200", description = "Ids returned"))
	public List<String> listIds(
			@Valid @ParameterObject CardFilterRequest filter,
			@Valid @ParameterObject CardPageRequest page) {
		return cardQueryService.idsMatching(filter.toFilter(), toPageQuery(page));
	}

	@GetMapping("/{cardId}")
	@Operation(summary = "One card with its schedule and tags")
	@ApiResponses({
			@ApiResponse(responseCode = "200", description = "Card found"),
			@ApiResponse(responseCode = "404", description = "Card not found, or in Trash")
	})
	public CardListResponse detail(@PathVariable String cardId) {
		return CardListResponse.from(cardQueryService.detail(cardId));
	}

	/**
	 * One page of review history, newest first.
	 *
	 * <p>The cursor is two parameters rather than one opaque token because both halves are
	 * meaningful and a client resuming a page needs to be able to see what it is resuming from.
	 * Send back the {@code nextCursor} from the previous response.
	 */
	@GetMapping("/{cardId}/history")
	@Operation(summary = "A card's review history, newest first, keyset-paged")
	@ApiResponses({
			@ApiResponse(responseCode = "200", description = "History page returned"),
			@ApiResponse(responseCode = "400", description = "Invalid limit or partial cursor")
	})
	public CardHistoryResponse history(
			@PathVariable String cardId,
			@Valid @ParameterObject CardHistoryRequest request) {
		return CardHistoryResponse.from(
				cardQueryService.history(cardId, request.toCursor(), request.effectiveLimit()));
	}

	@GetMapping("/state-counts")
	@Operation(summary = "How many of a deck's cards sit in each learning stage")
	@ApiResponses(@ApiResponse(responseCode = "200", description = "Counts returned"))
	public CardStateCountsResponse stateCounts(@RequestParam String deckId) {
		return CardStateCountsResponse.from(
				cardQueryService.stateCounts(deckId, StageThresholds.DEFAULTS));
	}

	private com.memox.common.pagination.PageQuery<com.memox.card.enums.CardSortField> toPageQuery(
			CardPageRequest page) {
		return page.toPageQuery(
				paginationProperties.getDefaultPage(), paginationProperties.getDefaultSize());
	}
}
