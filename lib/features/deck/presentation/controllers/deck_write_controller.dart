import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/state/submit_outcome.dart';
import '../../domain/models/scheduler_type_model.dart';
import '../providers/deck_use_case_provider.dart';
import '../states/deck_submit_state.dart';

part 'deck_write_controller.g.dart';

/// The deck mutations, one controller per operation.
///
/// **Why separate controllers rather than one with several flags.** Each of
/// these can be in flight while another is idle — a rename sheet open over a
/// list where a delete just failed — and a single controller would need one
/// submitting flag per operation, which is the shared-`isLoading` bug written
/// out longhand. Separate providers make "which operation is busy" a question
/// with only one possible answer.
///
/// Every one of them:
///
/// * refuses a second submit while the first is in flight ([DeckSubmitState
///   .canSubmit]), so a double tap cannot create two decks;
/// * calls a use case, which is where BR-01 and BR-11 are applied — the
///   controller does **not** validate, and neither does the repository. Delete,
///   reset and move validate nothing at all: they have no field to check;
/// * checks `ref.mounted` after the await, because a sheet can be dismissed
///   mid-write and writing state into a disposed controller is a crash;
/// * keeps the user's input on failure — none of them clears anything, the
///   widget holds the text (UC-02 E4, UC-03).
///
/// None of them navigates or shows a snackbar. They report a [SubmitOutcome] and
/// the widget reacts, because a controller that closed a route would need a handle
/// on the widget tree that it must never hold.
///
/// Only the two creators take a [SubmitDisposition]: rename, delete, reset and
/// move have nothing to add another of, so they always report `savedAndClose`.

/// Creates a root deck (UC-02).
@riverpod
class CreateRootDeckController extends _$CreateRootDeckController {
  @override
  DeckSubmitState build() => const DeckSubmitState();

  /// [schedulerType] is nullable on purpose: "not chosen yet" is a real state
  /// the form starts in, and BR-11 forbids defaulting it. Passing
  /// `SchedulerType.eightBox` as a placeholder is exactly the implicit default
  /// the rule exists to prevent.
  Future<void> submit({
    required String name,
    required SchedulerType? schedulerType,
    SubmitDisposition disposition = SubmitDisposition.close,
  }) async {
    if (!state.canSubmit) return;

    // No validation here. BR-01 and BR-11 belong to the domain, and the use case
    // checks them — the controller used to check them too, which meant the same
    // rule ran in `presentation/` and again in `data/` with nothing to catch the
    // two disagreeing. An invalid form now arrives as a `ValidationFailure` and
    // `deckSubmitFailure` turns it into the per-field problems below.
    state = const DeckSubmitState(isSubmitting: true);
    try {
      await ref.read(createRootDeckUseCaseProvider)(
        rawName: name,
        schedulerType: schedulerType,
      );
      if (!ref.mounted) return;
      state = DeckSubmitState(outcome: disposition.outcome);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = deckSubmitFailure(failure);
    }
  }

  /// Clears the last attempt so the form can be reopened cleanly.
  void reset() => state = const DeckSubmitState();
}

/// Creates a sub-deck under a parent (UC-08).
///
/// No scheduler argument: a sub-deck inherits from its root and must leave the
/// scheduler columns null (BR-06). The new deck starts `content_type = unset`,
/// and if the parent was `unset` it becomes `deck` in the same transaction —
/// both decided by the repository, not here (BR-62).
@riverpod
class CreateSubDeckController extends _$CreateSubDeckController {
  @override
  DeckSubmitState build(String parentDeckId) => const DeckSubmitState();

  Future<void> submit({
    required String name,
    SubmitDisposition disposition = SubmitDisposition.close,
  }) async {
    if (!state.canSubmit) return;

    state = const DeckSubmitState(isSubmitting: true);
    try {
      await ref.read(createSubDeckUseCaseProvider)(
        rawName: name,
        parentDeckId: parentDeckId,
      );
      if (!ref.mounted) return;
      state = DeckSubmitState(outcome: disposition.outcome);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = deckSubmitFailure(failure);
    }
  }

  void reset() => state = const DeckSubmitState();
}

/// Renames a deck (UC-03, BR-01).
///
/// Works for a root and a sub-deck alike: a rename touches the name and
/// `updated_at` and nothing else — not the scheduler, not the content type, not
/// the tree.
@riverpod
class RenameDeckController extends _$RenameDeckController {
  @override
  DeckSubmitState build(String deckId) => const DeckSubmitState();

  Future<void> submit({required String name}) async {
    if (!state.canSubmit) return;

    state = const DeckSubmitState(isSubmitting: true);
    try {
      await ref.read(renameDeckUseCaseProvider)(deckId: deckId, rawName: name);
      if (!ref.mounted) return;
      state = const DeckSubmitState(outcome: SubmitOutcome.savedAndClose);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = deckSubmitFailure(failure);
    }
  }

  void reset() => state = const DeckSubmitState();
}

/// Deletes a deck after its impact has been shown (UC-03, BR-03, BR-04).
@riverpod
class DeleteDeckController extends _$DeleteDeckController {
  @override
  DeckSubmitState build(String deckId) => const DeckSubmitState();

  /// Deletes, and **returns the batch id** so the caller can offer Undo
  /// (BR-182, BR-189).
  ///
  /// The id is a return value rather than a field on the state, and that is
  /// deliberate: it is useful for one frame — the snackbar that follows the
  /// dialog closing — and a stale one names a batch that has since been
  /// restored or purged. Keeping it in state would make it look durable.
  Future<String?> submit() async {
    if (!state.canSubmit) return null;

    state = const DeckSubmitState(isSubmitting: true);
    try {
      final batchId = await ref.read(deleteDeckForUndoUseCaseProvider)(deckId);
      if (!ref.mounted) return batchId;
      state = const DeckSubmitState(outcome: SubmitOutcome.savedAndClose);

      return batchId;
    } on Failure catch (failure) {
      if (!ref.mounted) return null;
      state = DeckSubmitState(failure: failure);

      return null;
    }
  }

  void reset() => state = const DeckSubmitState();
}

/// Resets a root deck's learning progress, onto a scheduler the user picks
/// (UC-07).
///
/// **The scheduler is a parameter of the submit, not of the controller.** It is
/// chosen inside the confirmation and can change up to the moment Reset is
/// pressed; holding it in the provider key would make every change a new
/// controller, and the submitting flag would reset with it.
@riverpod
class ResetLearningProgressController
    extends _$ResetLearningProgressController {
  @override
  DeckSubmitState build(String rootDeckId) => const DeckSubmitState();

  Future<void> submit({required SchedulerType schedulerType}) async {
    if (!state.canSubmit) return;

    state = const DeckSubmitState(isSubmitting: true);
    try {
      await ref.read(resetLearningProgressUseCaseProvider)(
        rootDeckId: rootDeckId,
        schedulerType: schedulerType,
      );
      if (!ref.mounted) return;
      state = const DeckSubmitState(outcome: SubmitOutcome.savedAndClose);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = DeckSubmitState(failure: failure);
    }
  }

  void reset() => state = const DeckSubmitState();
}

/// Changes a root deck's study mode while it is still unlocked (UC-03, BR-12).
///
/// Separate from [ResetLearningProgressController] for the same reason the use
/// cases are separate: these two can be in flight independently, and only one of
/// them is destructive. Sharing a controller would mean one submitting flag for
/// two confirmations that say opposite things about what the user is about to
/// lose.
@riverpod
class ChangeUnlockedSchedulerController
    extends _$ChangeUnlockedSchedulerController {
  @override
  DeckSubmitState build(String rootDeckId) => const DeckSubmitState();

  Future<void> submit({required SchedulerType schedulerType}) async {
    if (!state.canSubmit) return;

    state = const DeckSubmitState(isSubmitting: true);
    try {
      await ref.read(changeUnlockedSchedulerUseCaseProvider)(
        rootDeckId: rootDeckId,
        schedulerType: schedulerType,
      );
      if (!ref.mounted) return;
      state = const DeckSubmitState(outcome: SubmitOutcome.savedAndClose);
    } on Failure catch (failure) {
      // The lock landing between the sheet opening and this submit is a normal
      // outcome, not a bug: the repository re-reads it inside the transaction
      // (BR-13). It arrives here as a `ConflictFailure` and the sheet renders
      // the reason.
      if (!ref.mounted) return;
      state = DeckSubmitState(failure: failure);
    }
  }

  void reset() => state = const DeckSubmitState();
}

/// Moves a deck and its whole subtree under another parent (UC-09).
///
/// The picker disables targets it can already tell are illegal, but this still
/// submits to `moveDeck`, which re-runs every rule inside the transaction. The
/// UI check explains; the repository check is what makes the write safe. A
/// stale picker must never be able to widen what the database accepts.
@riverpod
class MoveDeckController extends _$MoveDeckController {
  @override
  DeckSubmitState build(String deckId) => const DeckSubmitState();

  Future<void> submit({required String targetParentDeckId}) async {
    if (!state.canSubmit) return;

    state = const DeckSubmitState(isSubmitting: true);
    try {
      await ref.read(moveDeckUseCaseProvider)(
        deckId: deckId,
        targetParentDeckId: targetParentDeckId,
      );
      if (!ref.mounted) return;
      state = const DeckSubmitState(outcome: SubmitOutcome.savedAndClose);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = DeckSubmitState(failure: failure);
    }
  }

  void reset() => state = const DeckSubmitState();
}
