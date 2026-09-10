package com.memox.deck.entity;

import com.memox.common.tree.DeckAncestor;

import java.time.Instant;
import java.util.List;

import com.memox.deck.enums.DeckContentType;
import com.memox.common.scheduler.SchedulerType;

/**
 * One row of the level statement, before the service folds it into a {@link DeckLevel}.
 *
 * <p>Flat and wide on purpose. MyBatis can nest a result map inside a constructor argument, but
 * this module has already paid once for a subtle mapping mistake that produced no error and no
 * value — {@code javaType="int"} silently meaning {@code Integer}. A flat row of scalars is
 * checkable by reading it, and the folding is ordinary Java in the service where it can be tested.
 *
 * <p>The parent columns and {@code ancestry} repeat identically on every row, because the statement
 * returns one row per child and the header belongs to all of them. {@code nextDueAt} repeats for
 * the same reason: it is the level's timer, not a child's.
 *
 * <p>Child columns are nullable. The join to children is a LEFT JOIN, so a deck with no children
 * still yields one row — a header with no child, which the service drops rather than turning into
 * a child made of nulls.
 */
public record DeckLevelRow(
		String parentId,
		String parentName,
		DeckContentType parentContentType,
		List<DeckAncestor> ancestry,
		Instant nextDueAt,
		String childId,
		String childName,
		String childParentDeckId,
		String childRootDeckId,
		DeckContentType childContentType,
		Integer childSiblingPosition,
		Instant childCreatedAt,
		Instant childUpdatedAt,
		SchedulerType inheritedSchedulerType,
		long totalCardCount,
		long newCardCount,
		long dueCardCount,
		long overdueCardCount,
		Instant oldestDueAt,
		long learnedCardCount,
		long subDeckCount) {

	public DeckLevelRow {
		ancestry = List.copyOf(ancestry);
	}

	public boolean hasChild() {
		return childId != null;
	}
}
