package com.memox.card.dto.response;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.memox.card.entity.ExportCard;

/**
 * One card as it reaches the client that writes the file: AD-20's six canonical fields.
 *
 * <p>BR-175 governs what lands in the file's cells, and this response <em>is</em> those cells — so
 * the card id and its creation time stop at the service. Carrying them would let a client write
 * them, and re-importing the artifact must mint a new card rather than restore an old one.
 *
 * <p>An absent optional field is absent, never {@code "-"} or the string {@code "null"}: BR-179
 * wants an empty cell, and null is the only value that maps to one without the client guessing.
 *
 * <p>The tags are a list. BR-176 puts the {@code ;}-with-escapes codec in one place shared by import
 * and export; joining them here would be the second copy that rule exists to prevent.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ExportCardResponse(String front, String back, String example, String hint,
		String pronunciation, List<String> tagNames) {

	public ExportCardResponse {
		tagNames = List.copyOf(tagNames);
	}

	public static ExportCardResponse from(ExportCard card) {
		return new ExportCardResponse(card.front(), card.back(), card.example(), card.hint(),
				card.pronunciation(), card.tagNames());
	}
}
