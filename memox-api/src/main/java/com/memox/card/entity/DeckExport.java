package com.memox.card.entity;

import java.util.List;

/**
 * One export: the deck's name and its cards, from one snapshot.
 *
 * <p>BR-177 requires both to come from a single consistent read. A name taken before a rename beside
 * rows taken after it is a file nobody can explain, which is why the name is read inside the same
 * transaction as the cards rather than beside them.
 *
 * <p>The name is here for BR-180's file name. Sanitising it and appending a date is the client's
 * job — the date has to come from the client's own clock, and the file name must never be logged.
 */
public record DeckExport(String deckName, List<ExportCard> cards) {

	public DeckExport {
		cards = cards == null ? List.of() : List.copyOf(cards);
	}
}
