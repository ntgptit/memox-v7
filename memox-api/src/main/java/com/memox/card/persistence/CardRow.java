package com.memox.card.persistence;

import java.time.Instant;
import java.util.Locale;

import com.memox.card.domain.Card;

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
	public String getId() { return id; }
	public void setId(String id) { this.id = id; }
	public String getDeckId() { return deckId; }
	public void setDeckId(String deckId) { this.deckId = deckId; }
	public String getFront() { return front; }
	public void setFront(String front) { this.front = front; }
	public String getBack() { return back; }
	public void setBack(String back) { this.back = back; }
	public boolean isFlagged() { return flagged; }
	public void setFlagged(boolean flagged) { this.flagged = flagged; }
	public String getExample() { return example; }
	public void setExample(String example) { this.example = example; }
	public String getHint() { return hint; }
	public void setHint(String hint) { this.hint = hint; }
	public String getPronunciation() { return pronunciation; }
	public void setPronunciation(String pronunciation) { this.pronunciation = pronunciation; }
	public Instant getCreatedAt() { return createdAt; }
	public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
	public Instant getUpdatedAt() { return updatedAt; }
	public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
