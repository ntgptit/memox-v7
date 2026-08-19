part of 'trash_repository_impl.dart';

/// The purge half of [TrashRepositoryImpl] (BR-264, BR-265).
///
/// **Purge is `DELETE FROM delete_batches` and nothing else.** Both tombstone
/// columns reference that table `ON DELETE CASCADE`, so removing the batch row
/// removes its decks and cards, and their own cascades remove study states,
/// answers, queue rows and tag links. The work here is entirely in what must be
/// true *before* that one statement runs.
mixin _TrashPurgeOperations implements TrashRepository {
  TrashDao get _dao;

  Future<T> _guard<T>(Future<T> Function() action);

  @override
  Future<void> purge(List<String> batchIds) => _guard(
    () => _dao.runInTransaction(() async {
      if (batchIds.isEmpty) return;

      // Every named batch must still be there. A selection naming one that a
      // sweep already took is describing a database that has moved on, and
      // purging "the rest" would act on a set the user never saw — the same
      // rule the card bulk operations apply (UC-21 E6).
      for (final batchId in batchIds) {
        if (await _dao.batchById(batchId) != null) continue;
        throw const NotFoundFailure(
          message: 'That item is no longer in Trash.',
        );
      }

      await _purgeAll(batchIds, allowed: batchIds, skipBlocked: false);
    }),
  );

  @override
  Future<int> purgeExpired(DateTime now) => _guard(
    () => _dao.runInTransaction(() async {
      final eligible = await _dao.eligibleBatches(
        // `<= cutoff`, so a batch at exactly thirty days goes (BR-264). The
        // moment arrives as a value: nothing below the composition root reads
        // a clock (AD-06).
        TrashRetention.cutoffFor(now),
      );
      if (eligible.isEmpty) return 0;

      final ids = <String>[for (final batch in eligible) batch.id];

      // **Skipped, not refused.** Nobody asked for this sweep, so a batch whose
      // cascade would reach something still protected must not take the rest of
      // the sweep down with it. A user-requested purge is the opposite: they
      // named these, so a blocker is an answer they have to see.
      return _purgeAll(ids, allowed: ids, skipBlocked: true);
    }),
  );

  /// Removes each of [batchIds] whose cascade stays inside [allowed].
  ///
  /// Oldest first. Not required for correctness — every batch row is deleted
  /// explicitly, and a cascade can only reach rows of batches deleted no later
  /// than this one (invariant 36), which are all inside [allowed] by the check
  /// above — but it makes the order the same on every run, which is what makes
  /// a failure reproducible.
  Future<int> _purgeAll(
    List<String> batchIds, {
    required List<String> allowed,
    required bool skipBlocked,
  }) async {
    var purged = 0;
    for (final batchId in batchIds) {
      final blockers = await _dao.purgeBlockerCount(
        batchId: batchId,
        allowedBatchIds: allowed,
      );
      if (blockers > 0) {
        if (skipBlocked) continue;

        throw const ConflictFailure(
          message: 'Refused: the purge would reach rows outside this batch.',
          reason: TrashConflictReason.purgeWouldTakeAnotherBatch,
        );
      }

      await _dao.purgeBatch(batchId);
      purged++;
    }

    return purged;
  }
}
