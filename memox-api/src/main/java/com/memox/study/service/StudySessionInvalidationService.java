package com.memox.study.service;

import java.time.Instant;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;

import org.springframework.stereotype.Service;

import com.memox.study.enums.StudySessionEndReason;
import com.memox.study.enums.StudySessionStatus;
import com.memox.study.persistence.StudyMapper;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Closing the sessions a deletion takes the material out from under (BR-259).
 *
 * <p><strong>This lives in the study module and not in Trash, and that placement is the rule.</strong>
 * The {@code (status, end_reason)} pair is the study module's invariant, and Trash may not write it
 * behind that module's back. So Trash asks for a verb, and the verb owns both columns: no caller
 * chooses either half, which is what makes an illegal pair unwritable rather than merely
 * discouraged. Nothing in the Postgres schema enforces pair legality — the column CHECKs are two
 * independent lists, not a compound one — so structure is the whole of the guarantee.
 *
 * <p><strong>No {@code @Transactional} here, deliberately.</strong> This is called from inside the
 * deletion's own transaction. A second one would be a savepoint that can commit while the deletion
 * around it rolls back, producing the one outcome BR-259 forbids: a session closed for a deletion
 * that never happened. Spring's default {@code REQUIRED} propagation joins the caller's transaction,
 * and {@code REQUIRES_NEW} would recreate exactly that hazard.
 *
 * <p>Nothing here logs deck or card content (BR-267) — session ids and counts only.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class StudySessionInvalidationService {

	private final StudyMapper studyMapper;

	/**
	 * Closes every open session a deletion has just affected.
	 *
	 * <p><strong>Two id sets, because there are two ways a session can be affected and only one of
	 * them is visible from the deck side.</strong> A session opened on a deck in the deleted set is
	 * the obvious one. The other is a session reviewing a whole root whose queue happens to hold one
	 * of these cards — its own {@code deck_id} is the root, and the root is not in the batch. Passing
	 * only the deck ids leaves that session running over material the user can no longer see.
	 *
	 * <p><strong>Call this before marking the rows.</strong> The lookups take the id sets the
	 * deletion has already decided on, and those ids have to still describe live rows — a tombstone
	 * is invisible to the reads that gathered them.
	 *
	 * @param endedAt the instant the deletion itself carries, not a fresh clock read: a session that
	 *     ended a few milliseconds after the batch it was invalidated for is one nobody can line up
	 *     with anything later
	 * @return how many sessions were closed
	 */
	public int invalidateForDeletedContent(
			Collection<String> deckIds, Collection<String> cardIds, Instant endedAt) {
		final var sessionIds = new LinkedHashSet<String>();
		if (!deckIds.isEmpty()) {
			sessionIds.addAll(studyMapper.findOpenSessionIdsForDecks(deckIds));
		}
		if (!cardIds.isEmpty()) {
			sessionIds.addAll(studyMapper.findOpenSessionIdsForCards(cardIds));
		}
		if (sessionIds.isEmpty()) {
			return 0;
		}

		final var closed = studyMapper.invalidateSessions(List.copyOf(sessionIds),
				StudySessionStatus.INVALIDATED, StudySessionEndReason.CONTENT_DELETED, endedAt);
		log.info("Invalidated {} in-progress session(s) over deleted content", closed);
		return closed;
	}
}
