package com.memox.trash.service;

import java.time.Clock;
import java.time.Instant;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.common.error.ApiErrorCode;
import com.memox.common.persistence.IdCollections;
import com.memox.trash.entity.DeleteBatch;
import com.memox.trash.exception.TrashConflictException;
import com.memox.trash.exception.TrashNotFoundException;
import com.memox.trash.persistence.TrashMapper;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * The retention sweep (BR-264, BR-265).
 *
 * <p><strong>A purge is {@code DELETE FROM delete_batches} and nothing else.</strong> Both tombstone
 * columns reference that table {@code ON DELETE CASCADE}, so removing the batch row removes its
 * decks and cards, and their own cascades carry away the study states, the answers, the queue rows
 * and the tag links. All the work is in what has to be true <em>before</em> that one statement runs.
 *
 * <p><strong>The same blocker signal means opposite things to the two callers, and that is why the
 * probe takes its allowed set as a parameter.</strong> {@link #purgeExpired()} is a sweep nobody
 * asked for, so a blocked batch is left whole rather than taking the rest of the sweep down with it
 * — and it is usually blocked only until a descendant’s own thirty days run out. {@link #purge} is
 * a purge a user named and confirmed by an exact count, so a blocker is an answer they have to see:
 * it refuses, and refuses whole.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TrashPurgeService {

	private static final String BATCH_IDS = "batchIds";

	private final TrashMapper trashMapper;
	private final Clock clock;

	/**
	 * Removes every batch past retention whose cascade stays inside the eligible set.
	 *
	 * <p>Idempotent, and cheap when there is nothing to do: one indexed read that returns no rows.
	 * It is safe on every trigger BR-264 names — app start, resume, and opening Trash — and it must
	 * not depend on the user opening Trash at all.
	 *
	 * <p>Oldest first. Not required for correctness — every batch row is deleted explicitly, and a
	 * cascade can only reach rows of batches deleted no later than this one — but it makes the order
	 * the same on every run, which is what makes a failure reproducible.
	 */
	@Transactional
	public PurgeReport purgeExpired() {
		final var cutoff = RetentionPolicy.cutoff(Instant.now(clock));
		final var eligible = trashMapper.findEligibleBatches(cutoff);
		if (eligible.isEmpty()) {
			return new PurgeReport(0, 0);
		}

		final var allowed = eligible.stream().map(DeleteBatch::id).toList();
		var purged = 0;
		var skipped = 0;
		for (final var batch : eligible) {
			if (trashMapper.countPurgeBlockers(batch.id(), allowed) > 0) {
				skipped++;
				continue;
			}
			trashMapper.deleteBatch(batch.id());
			purged++;
		}

		log.info("Retention sweep purged {} batch(es) and skipped {} at cutoff {}",
				purged, skipped, cutoff);
		return new PurgeReport(purged, skipped);
	}

	/**
	 * The purge a user named and confirmed (BR-266). No retention wait: they asked.
	 *
	 * <p>Every refusal is whole. A confirmation named an exact count before this call was made, so
	 * purging fewer batches than were named would break the promise that dialog already made.
	 *
	 * <p><strong>The existence check runs first and on its own</strong>, never folded into the
	 * blocker probe: purging "the rest" would act on a set the user never saw.
	 *
	 * <p><strong>The allowed set is exactly what was named</strong>, never "everything past
	 * retention". Conflating the two would let this request quietly carry away unrelated batches
	 * that happened to be old enough.
	 *
	 * @throws com.memox.common.error.ValidationFailedException on an empty or oversized selection
	 * @throws TrashNotFoundException when a named batch is no longer in Trash (UC-21 E6)
	 * @throws TrashConflictException when the selection mixes item types, or a cascade would reach a
	 *     batch the user did not name
	 */
	@Transactional
	public PurgeReport purge(Collection<String> batchIds) {
		// Deduplicated, in the order they arrived. A repeated id is one batch, exactly as a repeated
		// card id is one row in an export (BR-174): purging it twice is impossible anyway, but
		// counting it twice would report a number the confirmation never named.
		final var named = List.copyOf(new LinkedHashSet<>(
				IdCollections.requireUsableBatch(batchIds, BATCH_IDS)));
		final var batches = named.stream().map(this::requireBatch).toList();
		requireOneItemType(batches);

		for (final var batch : batches) {
			if (trashMapper.countPurgeBlockers(batch.id(), named) > 0) {
				throw new TrashConflictException(ApiErrorCode.PURGE_BLOCKED, batch.id());
			}
			trashMapper.deleteBatch(batch.id());
		}

		log.info("Purged {} batch(es) on request", batches.size());
		return new PurgeReport(batches.size(), 0);
	}

	private DeleteBatch requireBatch(String batchId) {
		final var batch = trashMapper.findBatchById(batchId);
		if (batch == null) {
			throw new TrashNotFoundException(batchId);
		}
		return batch;
	}

	/**
	 * BR-266: one permanent delete handles cards or decks, never both.
	 *
	 * <p><strong>Enforced here rather than ported.</strong> The Flutter app holds this in its
	 * selection state, where a row of the wrong kind simply cannot be picked, and its repository has
	 * no such check because nothing can reach it with a mixed list. An HTTP client has no selection
	 * state, so at this boundary the rule is unenforced unless the endpoint enforces it.
	 */
	private void requireOneItemType(List<DeleteBatch> batches) {
		final var first = batches.get(0).itemType();
		final var mixed = batches.stream().filter(batch -> batch.itemType() != first).findFirst();
		if (mixed.isEmpty()) {
			return;
		}
		throw new TrashConflictException(ApiErrorCode.PURGE_MIXES_ITEM_TYPES, mixed.get().id());
	}
}
