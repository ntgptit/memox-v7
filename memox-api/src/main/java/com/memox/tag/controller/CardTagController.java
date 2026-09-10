package com.memox.tag.controller;

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

import com.memox.tag.dto.request.AttachTagRequest;
import com.memox.tag.dto.response.TagResponse;
import com.memox.tag.service.AttachTagCommand;
import com.memox.tag.service.CardTagService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

/**
 * Tags on cards, under the card's own path because that is the resource being changed.
 *
 * <p>{@code bulk-tag} sits beside the {@code bulk-move} and {@code bulk-flag} the card module
 * already publishes: all three are BR-166 batch mutations and a client that can select rows uses
 * them the same way. A single card is a one-element batch, which is exactly how the Flutter
 * repository implements its single-card path.
 */
@RestController
@RequestMapping("/api/v1/cards")
@RequiredArgsConstructor
@Tag(name = "Tags")
public class CardTagController {

	private final CardTagService cardTagService;

	@PostMapping("/bulk-tag")
	@Operation(summary = "Attach one tag to a batch of cards, or attach it to none of them")
	@ApiResponses({
			@ApiResponse(responseCode = "200", description = "The tag every card now carries"),
			@ApiResponse(responseCode = "400", description = "Empty batch, more than 500 ids, or an invalid name"),
			@ApiResponse(responseCode = "404", description = "An id names no active card"),
			@ApiResponse(responseCode = "409", description = "A card that would gain the tag is at the ten-tag ceiling")
	})
	public TagResponse attach(@Valid @RequestBody AttachTagRequest request) {
		return TagResponse.from(
				cardTagService.attach(new AttachTagCommand(request.cardIds(), request.name())));
	}

	@GetMapping("/{cardId}/tags")
	@Operation(summary = "The tags one card carries, with their ids")
	@ApiResponses(@ApiResponse(responseCode = "200", description = "Tags returned"))
	public List<TagResponse> tagsForCard(@PathVariable String cardId) {
		return cardTagService.tagsForCard(cardId).stream().map(TagResponse::from).toList();
	}

	@DeleteMapping("/{cardId}/tags/{tagId}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	@Operation(summary = "Remove one tag from one card")
	@ApiResponses(@ApiResponse(responseCode = "204", description = "The card no longer carries the tag"))
	public void detach(@PathVariable String cardId, @PathVariable String tagId) {
		cardTagService.detach(cardId, tagId);
	}
}
