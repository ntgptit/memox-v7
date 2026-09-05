package com.memox.deck.persistence;

import java.time.Instant;

import com.memox.deck.domain.Deck;
import com.memox.deck.domain.DeckContentType;
import com.memox.deck.domain.SchedulerType;

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
public class DeckRow {

	private String id;
	private String name;
	private String parentDeckId;
	private String rootDeckId;
	private DeckContentType contentType;
	private SchedulerType schedulerType;
	private Integer schedulerVersion;
	private Integer schedulerGeneration;
	private int siblingPosition;
	private Instant createdAt;
	private Instant updatedAt;

	public Deck toDomain() {
		return new Deck(id, name, parentDeckId, rootDeckId, contentType, schedulerType,
				schedulerVersion, schedulerGeneration, siblingPosition, createdAt, updatedAt);
	}
}
