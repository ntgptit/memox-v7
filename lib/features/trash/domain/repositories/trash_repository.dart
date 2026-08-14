import '../entities/trash_batch_entity.dart';
import '../models/trash_restore_target_model.dart';

/// Everything Trash does to a batch after it exists (UC-12).
///
/// The other half — creating a batch — is `ContentTrashRepository`, called by
/// the Deck and Card features from inside their own delete transactions. Two
/// contracts because they have two callers and two lifetimes: one is used by
/// the delete paths of other features, this one only by the Trash screen.
abstract interface class TrashRepository {
  /// Every batch, newest first (UC-12 step 3).
  ///
  /// A stream, so an auto-purge or a restore anywhere in the app removes the
  /// row in place rather than through a reload the screen has to remember to
  /// ask for (wireframe T12).
  Stream<List<TrashBatchEntity>> watchBatches();

  /// One batch, or a `NotFoundFailure` when it has already been purged
  /// (UC-12 E6).
  Future<TrashBatchEntity> batch(String batchId);

  /// Where [batchId] may be restored to, live (BR-187).
  ///
  /// Built from the **production** eligibility rules — `cardMoveTargets` for a
  /// card, the move rejection set for a sub-deck, and exactly one top-level
  /// entry for a root deck. Only targets that would be accepted are returned,
  /// so the picker has nothing to disable.
  Stream<List<TrashRestoreTarget>> watchRestoreTargets(String batchId);

  /// Restores [batchId] into [target], in one transaction (BR-187, BR-188).
  ///
  /// Revives exactly the rows carrying this batch — a descendant tombstoned by
  /// an older batch stays where it is (BR-184) — re-parents the item root,
  /// rewrites `root_deck_id` for the whole subtree including the tombstones
  /// inside it, and sets an `unset` target's content type. Every rule is
  /// re-checked here, inside the transaction: the picker decided what to
  /// *offer*, this decides what may be *written*.
  Future<void> restore({
    required String batchId,
    required TrashRestoreTarget target,
  });

  /// Puts [batchId] back exactly where it was, without asking (BR-189).
  ///
  /// The origin is not stored anywhere special: a tombstone keeps its
  /// `parent_deck_id`/`deck_id`, so "where it was" is simply where it still
  /// points. The same rules as [restore] are applied to that origin, and a
  /// refusal is `undoOriginUnavailable` rather than a silent landing somewhere
  /// else.
  Future<void> undo(String batchId);

  /// Hard-deletes [batchIds] (BR-191).
  ///
  /// One transaction for the whole set: a purge that succeeded for three of
  /// five would leave the user with a confirmation that named five. A batch
  /// whose cascade would reach rows outside the eligible set refuses the
  /// operation rather than being skipped quietly — the user chose these.
  Future<void> purge(List<String> batchIds);

  /// Purges everything past retention, idempotently (BR-190).
  ///
  /// Called at startup, on resume and whenever Trash opens, so it must be safe
  /// to run twice a millisecond apart. A batch whose cascade would reach a
  /// batch that is not yet eligible is **skipped**, not refused: nobody asked
  /// for it, and failing the sweep would block every other batch behind it.
  ///
  /// Returns how many batches went. [now] is passed in — no layer reads the
  /// wall clock (AD-06).
  Future<int> purgeExpired(DateTime now);
}
