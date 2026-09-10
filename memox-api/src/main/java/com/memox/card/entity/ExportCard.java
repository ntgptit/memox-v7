package com.memox.card.entity;

import java.util.List;

/**
 * One card as the export carries it: AD-20's six content fields, plus the id.
 *
 * <p><strong>The id stops here.</strong> BR-175 draws the line between a content transfer and a
 * backup, and the id is on the backup side — re-importing the artifact must mint a new card, not
 * restore an old one. It is read because it is the only way to name which requested id did not come
 * back (BR-174), and the response DTO drops it.
 *
 * <p>{@code created_at} is not carried at all. Drift reads it because the selected scope runs in
 * chunks there and the concatenation of several ordered statements is not itself ordered; here one
 * statement answers a batch capped at 500 ids against a 65 535 bind limit, so the ORDER BY in the
 * SQL is the whole guarantee and a Java re-sort would have nothing to add.
 *
 * <p>No flag, no schedule, no history (BR-175). The tags are a list, not a joined cell: BR-176 puts
 * the {@code ;}-with-escapes codec in one place shared by import and export, and that place is the
 * client. A second encoder here is the second copy that rule exists to prevent.
 */
public record ExportCard(String cardId, String front, String back, String example, String hint,
		String pronunciation, List<String> tagNames) {

	public ExportCard {
		tagNames = tagNames == null ? List.of() : List.copyOf(tagNames);
	}
}
