import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/state/retry_policy.dart';
import '../../../../core/state/submit_outcome.dart';
import '../../../../core/time/clock_provider.dart';
import '../../domain/entities/trash_batch_entity.dart';
import '../../domain/models/trash_restore_target_model.dart';
import '../providers/trash_use_case_provider.dart';
import '../states/trash_state.dart';

part 'trash_controller.g.dart';

/// The Trash list, swept before it is shown (UC-12 step 3, BR-190).
///
/// **The sweep runs here rather than in the screen**, because "opening Trash"
/// is one of the three moments BR-190 names and a widget's `initState` is not a
/// place a rule can be found. It runs once per subscription, before the first
/// emission, and it is idempotent — the other two triggers (startup, resume)
/// may have run milliseconds ago.
///
/// A failure in the sweep does **not** fail the list. A user who opens Trash to
/// rescue something must see it even if the sweep could not finish; the batches
/// it failed to remove simply stay, which is the safe direction.
@Riverpod(retry: noAutomaticRetry)
Stream<List<TrashBatchEntity>> trashBatches(Ref ref) async* {
  final sweep = ref.watch(purgeExpiredTrashUseCaseProvider);
  try {
    await sweep(ref.watch(clockProvider)());
  } on Object {
    // Deliberately wide, and deliberately silent: the list is the point of this
    // screen and retention is a background chore. `purgeExpired` has already
    // mapped its own failures, and the next trigger will try again.
  }

  yield* ref.watch(watchTrashBatchesUseCaseProvider)();
}

/// Where one batch may go back to (BR-187).
///
/// `family` on the batch id, and `autoDispose` by default, so closing the
/// picker stops the query rather than leaving it watching the whole deck table.
@Riverpod(retry: noAutomaticRetry)
Stream<List<TrashRestoreTarget>> trashRestoreTargets(Ref ref, String batchId) =>
    ref.watch(watchTrashRestoreTargetsUseCaseProvider)(batchId);

/// Which kinds the list is showing. One value, one mutator.
@riverpod
class TrashFilterController extends _$TrashFilterController {
  @override
  TrashFilter build() => TrashFilter.all;

  void set(TrashFilter filter) => state = filter;
}

/// The rows the user has pointed at (BR-192).
///
/// Writes nothing itself — `TrashCommandController` owns every mutation — so a
/// refused restore never has to reconstruct a selection it had already cleared.
@riverpod
class TrashSelectionController extends _$TrashSelectionController {
  @override
  TrashSelectionState build() => const TrashSelectionState();

  /// Adds or removes [batch] (BR-192).
  ///
  /// A row of the other kind is **ignored**, not swapped for: the screen stops
  /// those rows responding at all and says why, so reaching this with a
  /// mismatched kind means something else went wrong, and silently changing the
  /// selection would hide it.
  void toggle(TrashBatchEntity batch) {
    if (!state.admits(batch)) return;

    final selected = <String>{...state.batchIds};
    if (!selected.remove(batch.batchId)) selected.add(batch.batchId);
    state = selected.isEmpty
        ? const TrashSelectionState()
        : TrashSelectionState(batchIds: selected, itemType: batch.itemType);
  }

  void clear() => state = const TrashSelectionState();
}

/// Restoring one batch into a chosen target (BR-187, BR-188).
///
/// **Three controllers rather than one with three methods**, and the rule is
/// not stylistic: a shared submit state means a shared `isSubmitting`, and the
/// spinner then appears on whichever action the user did not press. Each of
/// Trash's writes has its own failure, its own confirmation and its own place
/// on screen, so each gets its own state.
///
/// `family` on the batch id, so the row that is restoring is the row that shows
/// it — and so a refusal belongs to one row rather than to the screen.
///
/// Nothing here throws: the failure lands in [state] and the screen reads it. A
/// `try`/`catch` around an `await` inside a button handler is where `ref` gets
/// used after dispose.
@riverpod
class TrashRestoreController extends _$TrashRestoreController {
  @override
  TrashSubmitState build(String batchId) => const TrashSubmitState();

  Future<TrashSubmitState> submit(TrashRestoreTarget target) =>
      _runTrashCommand(
        read: () => state,
        write: (next) => state = next,
        isMounted: () => ref.mounted,
        action: () => ref.read(restoreTrashBatchUseCaseProvider)(
          batchId: batchId,
          target: target,
        ),
      );

  void reset() => state = const TrashSubmitState();
}

/// Reversing the deletion just made (BR-189).
///
/// Its own controller rather than a flag on the restore one: Undo is offered
/// from the screen the deletion happened on, which is usually not Trash at all,
/// and the two can be in flight from different places.
@riverpod
class TrashUndoController extends _$TrashUndoController {
  @override
  TrashSubmitState build(String batchId) => const TrashSubmitState();

  Future<TrashSubmitState> submit() => _runTrashCommand(
    read: () => state,
    write: (next) => state = next,
    isMounted: () => ref.mounted,
    action: () => ref.read(undoDeleteUseCaseProvider)(batchId),
  );

  void reset() => state = const TrashSubmitState();
}

/// Deleting the chosen batches for good (BR-191, BR-192).
///
/// Not a family: a purge acts on a set the user assembled, and the
/// confirmation they just read named exactly that set — so the state belongs to
/// the screen rather than to any one row.
@riverpod
class TrashPurgeController extends _$TrashPurgeController {
  @override
  TrashSubmitState build() => const TrashSubmitState();

  Future<TrashSubmitState> submit(List<String> batchIds) => _runTrashCommand(
    read: () => state,
    write: (next) => state = next,
    isMounted: () => ref.mounted,
    action: () => ref.read(purgeTrashBatchesUseCaseProvider)(batchIds),
  );

  void reset() => state = const TrashSubmitState();
}

/// The submit lifecycle the three controllers share (AD-12).
///
/// A free function taking the three things that differ — reading the state,
/// writing it, and whether the notifier is still mounted — because the shared
/// thing is the *sequence*, not the state. A mixin would have to reach for
/// `state`, which Riverpod's generated base makes protected, and a base class
/// would put three commands back behind one type.
///
/// **It returns the outcome as well as storing it**, and the caller uses the
/// return value. These controllers are `autoDispose` families, so a widget that
/// did `await submit()` and then `ref.read(provider)` could be reading a
/// freshly-rebuilt notifier with its initial state — the failure would be on
/// screen for no frames at all. Returning it removes the race rather than
/// papering over it with a keep-alive.
Future<TrashSubmitState> _runTrashCommand({
  required TrashSubmitState Function() read,
  required void Function(TrashSubmitState) write,
  required bool Function() isMounted,
  required Future<void> Function() action,
}) async {
  if (!read().canSubmit) return read();

  write(const TrashSubmitState(isSubmitting: true));
  try {
    await action();
    const done = TrashSubmitState(outcome: SubmitOutcome.savedAndClose);
    if (isMounted()) write(done);

    return done;
  } on Failure catch (failure) {
    final failed = TrashSubmitState(failure: failure);
    if (isMounted()) write(failed);

    return failed;
  }
}
