package com.memox.card.persistence;

import java.time.Instant;
import java.util.Locale;

import com.memox.card.domain.Card;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CardRow {

	private String id;
	private String deckId;
	private String front;
	private String back;
	private boolean flagged;
	private String example;
	private String hint;
	private String pronunciation;
	private Instant createdAt;
	private Instant updatedAt;

	public Card toDomain() {
		return new Card(id, deckId, front, back, flagged, example, hint, pronunciation, createdAt, updatedAt);
	}

	public String getFrontFolded() { return front.toLowerCase(Locale.ROOT); }
	public String getBackFolded() { return back.toLowerCase(Locale.ROOT); }
}
