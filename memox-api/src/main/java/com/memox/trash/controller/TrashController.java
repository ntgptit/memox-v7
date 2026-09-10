package com.memox.trash.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.memox.trash.dto.request.DeleteCardsRequest;
import com.memox.trash.dto.request.PurgeBatchesRequest;
import com.memox.trash.dto.request.RestoreBatchRequest;
import com.memox.trash.dto.response.DeleteBatchResponse;
import com.memox.trash.dto.response.PurgeReportResponse;
import com.memox.trash.dto.response.TrashBatchResponse;
import com.memox.trash.service.DeleteCardsCommand;
import com.memox.trash.service.DeleteDeckCommand;
import com.memox.trash.service.RestoreBatchCommand;
import com.memox.trash.service.TrashDeleteService;
import com.memox.trash.service.TrashPurgeService;
import com.memox.trash.service.TrashRestoreService;

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
	private final TrashRestoreService trashRestoreService;
	private final TrashPurgeService trashPurgeService;

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

	/**
	 * Everything still in Trash, newest first.
	 *
	 * <p>Unpaged: Trash holds thirty days of deletions and is read as a list to act on, not browsed.
	 */
	@GetMapping("/trash")
	@Operation(summary = "Every deletion still in Trash, newest first")
	@ApiResponses(@ApiResponse(responseCode = "200", description = "Trash listed"))
	public List<TrashBatchResponse> list() {
		// BR-264 names opening Trash as one of the three triggers, and the sweep is cheap when there
		// is nothing to do: one indexed read that returns no rows.
		trashPurgeService.purgeExpired();
		return trashRestoreService.list().stream().map(TrashBatchResponse::from).toList();
	}

	/**
	 * The retention sweep, for the client's start and resume hooks (BR-264).
	 *
	 * <p>No scheduler bean: the server does not own the app lifecycle, and BR-264 requires the sweep
	 * to run whether or not anyone opens Trash — which is a decision only the client can act on.
	 */
	/**
	 * Delete the named batches permanently (BR-266).
	 *
	 * <p>Not the sweep with a different trigger. The user named these and confirmed an exact count,
	 * so every refusal is whole: a batch that has already gone is a 404 for the request rather than
	 * a reason to purge the rest, and a cascade that would reach a batch they did not name is a 409
	 * rather than something to skip past.
	 */
	@PostMapping("/trash/purge")
	@Operation(summary = "Delete the named batches permanently")
	@ApiResponses({
			@ApiResponse(responseCode = "200", description = "How many batches were purged"),
			@ApiResponse(responseCode = "400", description = "Empty selection, or more than 500 ids"),
			@ApiResponse(responseCode = "404", description = "A named batch is no longer in Trash"),
			@ApiResponse(responseCode = "409", description = "Mixed item types, or a cascade beyond the selection")
	})
	public PurgeReportResponse purge(@Valid @RequestBody PurgeBatchesRequest request) {
		return PurgeReportResponse.from(trashPurgeService.purge(request.batchIds()));
	}

	@PostMapping("/trash/purge-expired")
	@Operation(summary = "Purge every batch past the thirty-day retention window")
	@ApiResponses(@ApiResponse(responseCode = "200", description = "What the sweep did"))
	public PurgeReportResponse purgeExpired() {
		return PurgeReportResponse.from(trashPurgeService.purgeExpired());
	}

	/**
	 * Puts one batch back, into a target the caller chose.
	 *
	 * <p>An absent {@code targetDeckId} means the top level — the one destination a root deck may
	 * use, and one no other item may. The refusals are the move's own (409), because a restore is
	 * held to the move's rules rather than to a second set written for it (BR-261).
	 */
	@PostMapping("/trash/{batchId}/restore")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	@Operation(summary = "Restore one batch into a chosen target")
	@ApiResponses({
			@ApiResponse(responseCode = "204", description = "The batch is back and no longer in Trash"),
			@ApiResponse(responseCode = "404", description = "The batch is no longer in Trash"),
			@ApiResponse(responseCode = "409", description = "The target cannot hold this item")
	})
	public void restore(
			@PathVariable String batchId,
			@RequestBody(required = false) RestoreBatchRequest request) {
		final var targetDeckId = request == null ? null : request.targetDeckId();
		trashRestoreService.restore(new RestoreBatchCommand(batchId, targetDeckId));
	}
}
