package com.memox.trash.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.memox.trash.dto.request.DeleteCardsRequest;
import com.memox.trash.dto.response.DeleteBatchResponse;
import com.memox.trash.service.DeleteCardsCommand;
import com.memox.trash.service.DeleteDeckCommand;
import com.memox.trash.service.TrashDeleteService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

/**
 * Moving content to Trash.
 *
 * <p>Both endpoints answer <strong>201</strong> rather than 204, and the difference is not
 * cosmetic: a soft-delete does not remove a thing, it <em>creates</em> a delete batch — the
 * resource an undo or a restore later acts on (BR-263). A 204 would tell a client the row is gone
 * and leave it nothing to undo with.
 */
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
@Tag(name = "Trash")
public class TrashController {

	private final TrashDeleteService trashDeleteService;

	@DeleteMapping("/decks/{deckId}")
	@ResponseStatus(HttpStatus.CREATED)
	@Operation(summary = "Move a deck and its whole active subtree to Trash")
	@ApiResponses({
			@ApiResponse(responseCode = "201", description = "The batch the deletion opened"),
			@ApiResponse(responseCode = "404", description = "Deck not found, or already in Trash")
	})
	public DeleteBatchResponse deleteDeck(@PathVariable String deckId) {
		return DeleteBatchResponse.from(trashDeleteService.deleteDeck(new DeleteDeckCommand(deckId)));
	}

	/**
	 * One batch per card, so the answer is a list (BR-256).
	 *
	 * <p>A single card is a one-element request. There is no second endpoint for it, because a
	 * second write path is a second place for the emptied-deck rule to be forgotten.
	 */
	@PostMapping("/cards/bulk-delete")
	@ResponseStatus(HttpStatus.CREATED)
	@Operation(summary = "Move a batch of cards to Trash, opening one batch per card")
	@ApiResponses({
			@ApiResponse(responseCode = "201", description = "One batch per card, in request order"),
			@ApiResponse(responseCode = "400", description = "Empty batch, or more than 500 ids"),
			@ApiResponse(responseCode = "404", description = "An id names no active card")
	})
	public List<DeleteBatchResponse> deleteCards(@Valid @RequestBody DeleteCardsRequest request) {
		return trashDeleteService.deleteCards(new DeleteCardsCommand(request.cardIds())).stream()
				.map(DeleteBatchResponse::from).toList();
	}
}
