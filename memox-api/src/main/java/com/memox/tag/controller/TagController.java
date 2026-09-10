package com.memox.tag.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.memox.tag.dto.request.RenameTagRequest;
import com.memox.tag.dto.response.TagCatalogResponse;
import com.memox.tag.dto.response.TagResponse;
import com.memox.tag.service.RenameTagCommand;
import com.memox.tag.service.TagCatalogService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

/** The tag management screen: the catalog, rename-or-merge, delete (BR-230, BR-233…BR-235). */
@RestController
@RequestMapping("/api/v1/tags")
@RequiredArgsConstructor
@Tag(name = "Tags")
public class TagController {

	private final TagCatalogService tagCatalogService;

	/**
	 * The whole library's tags, not one deck's (BR-230).
	 *
	 * <p>Unpaged on purpose: a tag list is bounded by how many names a person invents, the count on
	 * each row is what makes the screen useful, and paging it would put a tag with no cards on page
	 * four of a screen whose job is to let that tag be deleted.
	 */
	@GetMapping
	@Operation(summary = "Every tag with its active-card count, narrowed by an optional term")
	@ApiResponses(@ApiResponse(responseCode = "200", description = "Catalog returned"))
	public List<TagCatalogResponse> catalog(@RequestParam(defaultValue = "") String q) {
		return tagCatalogService.catalog(q).stream().map(TagCatalogResponse::from).toList();
	}

	@PatchMapping("/{tagId}")
	@Operation(summary = "Rename a tag, merging it when the folded name is already taken")
	@ApiResponses({
			@ApiResponse(responseCode = "200", description = "The tag that survived the rename"),
			@ApiResponse(responseCode = "400", description = "The name is blank, too long, or has control characters"),
			@ApiResponse(responseCode = "404", description = "Tag not found")
	})
	public TagResponse rename(
			@PathVariable String tagId,
			@Valid @RequestBody RenameTagRequest request) {
		return TagResponse.from(tagCatalogService.rename(new RenameTagCommand(tagId, request.name())));
	}

	@DeleteMapping("/{tagId}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	@Operation(summary = "Delete a tag and every link to it, leaving the cards untouched")
	@ApiResponses({
			@ApiResponse(responseCode = "204", description = "Tag deleted"),
			@ApiResponse(responseCode = "404", description = "Tag not found")
	})
	public void delete(@PathVariable String tagId) {
		tagCatalogService.delete(tagId);
	}
}
