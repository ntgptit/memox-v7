package com.memox.trash.service;

import java.time.Clock;
import java.time.Instant;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.trash.entity.DeleteBatch;
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
 * <p><strong>Skipped, not refused.</strong> Nobody asked for this sweep, so a batch whose cascade
 * would reach something still protected is left whole rather than taking the rest of the sweep down
 * with it — and it is usually protected only until a descendant's own thirty days run out. A
 * user-requested purge is the opposite case and would refuse; it has no caller yet, which is why
 * the blocker probe takes the allowed set as a parameter rather than assuming the retention cutoff.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TrashPurgeService {

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
}
