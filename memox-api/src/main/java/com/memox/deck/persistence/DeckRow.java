package com.memox.deck.persistence;

import java.time.Instant;

import com.memox.deck.domain.Deck;

public class DeckRow {

	private String id;
	private String name;
	private String parentDeckId;
	private String rootDeckId;
	private String contentType;
	private String schedulerType;
	private Integer schedulerVersion;
	private Integer schedulerGeneration;
	private int siblingPosition;
	private Instant createdAt;
	private Instant updatedAt;

	public Deck toDomain() {
		return new Deck(id, name, parentDeckId, rootDeckId, contentType, schedulerType,
				schedulerVersion, schedulerGeneration, siblingPosition, createdAt, updatedAt);
	}

	public String getId() { return id; }
	public void setId(String id) { this.id = id; }
	public String getName() { return name; }
	public void setName(String name) { this.name = name; }
	public String getParentDeckId() { return parentDeckId; }
	public void setParentDeckId(String parentDeckId) { this.parentDeckId = parentDeckId; }
	public String getRootDeckId() { return rootDeckId; }
	public void setRootDeckId(String rootDeckId) { this.rootDeckId = rootDeckId; }
	public String getContentType() { return contentType; }
	public void setContentType(String contentType) { this.contentType = contentType; }
	public String getSchedulerType() { return schedulerType; }
	public void setSchedulerType(String schedulerType) { this.schedulerType = schedulerType; }
	public Integer getSchedulerVersion() { return schedulerVersion; }
	public void setSchedulerVersion(Integer schedulerVersion) { this.schedulerVersion = schedulerVersion; }
	public Integer getSchedulerGeneration() { return schedulerGeneration; }
	public void setSchedulerGeneration(Integer schedulerGeneration) { this.schedulerGeneration = schedulerGeneration; }
	public int getSiblingPosition() { return siblingPosition; }
	public void setSiblingPosition(int siblingPosition) { this.siblingPosition = siblingPosition; }
	public Instant getCreatedAt() { return createdAt; }
	public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
	public Instant getUpdatedAt() { return updatedAt; }
	public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
