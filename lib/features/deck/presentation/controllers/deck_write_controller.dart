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
/// * validates against BR-01 locally before touching the database, so an empty
///   name is an inline error rather than a round trip;
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
        name: name,
        schedulerType: schedulerType,
      );
      if (!ref.mounted) return;
      state = DeckSubmitState(outcome: disposition.outcome);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = deckSubmitFailure(failure, name: name);
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
        name: name,
        parentDeckId: parentDeckId,
      );
      if (!ref.mounted) return;
      state = DeckSubmitState(outcome: disposition.outcome);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = deckSubmitFailure(failure, name: name);
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
      await ref.read(renameDeckUseCaseProvider)(deckId: deckId, name: name);
      if (!ref.mounted) return;
      state = const DeckSubmitState(outcome: SubmitOutcome.savedAndClose);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = deckSubmitFailure(failure, name: name);
    }
  }

  void reset() => state = const DeckSubmitState();
}

/// Deletes a deck after its impact has been shown (UC-03, BR-03, BR-04).
@riverpod
class DeleteDeckController extends _$DeleteDeckController {
  @override
  DeckSubmitState build(String deckId) => const DeckSubmitState();

  Future<void> submit() async {
    if (!state.canSubmit) return;

    state = const DeckSubmitState(isSubmitting: true);
    try {
      await ref.read(deleteDeckUseCaseProvider)(deckId);
      if (!ref.mounted) return;
      state = const DeckSubmitState(outcome: SubmitOutcome.savedAndClose);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = DeckSubmitState(failure: failure);
    }
  }

  void reset() => state = const DeckSubmitState();
}

/// Puts an empty sub-deck's content type back to `unset` (UC-03 A3, BR-68).
///
/// The screen only offers this when it believes the deck is empty, but the
/// repository is the boundary that decides: the tree can change between the
/// dialog opening and the confirm landing, and a `ConflictFailure` then arrives
/// here and is rendered as a conflict message rather than a crash.
@riverpod
class ResetContentTypeController extends _$ResetContentTypeController {
  @override
  DeckSubmitState build(String deckId) => const DeckSubmitState();

  Future<void> submit() async {
    if (!state.canSubmit) return;

    state = const DeckSubmitState(isSubmitting: true);
    try {
      await ref.read(resetDeckContentTypeUseCaseProvider)(deckId);
      if (!ref.mounted) return;
      state = const DeckSubmitState(outcome: SubmitOutcome.savedAndClose);
    } on Failure catch (failure) {
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
