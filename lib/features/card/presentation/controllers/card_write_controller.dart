import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/state/submit_outcome.dart';
import '../providers/card_use_case_provider.dart';
import '../states/card_submit_state.dart';

part 'card_write_controller.g.dart';

/// The two card mutations the editor drives past creation: edit and delete.
///
/// Separate controllers, and separate from `CardCreate`, for the reason
/// `DeckWriteController` spells out: each can be in flight while another is idle
/// — a delete confirm open over an editor that is mid-save — and one controller
/// with a flag per operation is the shared-`isLoading` bug written longhand.
///
/// Both follow the create controller's contract exactly: refuse a second submit
/// while the first is in flight, validate nothing themselves (the use case owns
/// BR-07/BR-08, delete has no field to check), check `ref.mounted` after the
/// await, keep the user's input on failure, and navigate nothing — they report a
/// [SubmitOutcome] and the screen reacts.

/// Edits one card's content (UC-04 A1, BR-10).
///
/// No [SubmitDisposition]: an edit has nothing to add another of, so it always
/// reports `savedAndClose`. The study state and history are untouched — the
/// repository writes only to `cards`, so BR-10 holds structurally.
@riverpod
class CardEdit extends _$CardEdit {
  @override
  CardSubmitState build(String cardId) => const CardSubmitState();

  Future<void> submit({
    required String rawFront,
    required String rawBack,
    String rawExample = '',
    String rawHint = '',
    String rawPronunciation = '',
  }) async {
    if (!state.canSubmit) return;

    state = const CardSubmitState(isSubmitting: true);
    try {
      await ref.read(updateCardUseCaseProvider)(
        cardId: cardId,
        rawFront: rawFront,
        rawBack: rawBack,
        rawExample: rawExample,
        rawHint: rawHint,
        rawPronunciation: rawPronunciation,
      );
      if (!ref.mounted) return;
      state = const CardSubmitState(outcome: SubmitOutcome.savedAndClose);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = cardSubmitFailure(failure);
    }
  }

  /// Clears the last attempt so the editor can be reopened cleanly.
  void reset() => state = const CardSubmitState();
}

/// Deletes one card (UC-04 A2, BR-163).
///
/// The card's study state and history cascade; the deck's `content_type` is
/// left as it is, even for the last card. The confirmation is the screen's job —
/// this only performs the delete once the user has confirmed.
@riverpod
class CardDelete extends _$CardDelete {
  @override
  CardSubmitState build(String cardId) => const CardSubmitState();

  /// Deletes, and **returns the batch id** so the caller can offer Undo
  /// (BR-256, BR-263).
  ///
  /// The id is a return value rather than a field on the state: it is useful
  /// for one frame, and a stale one names a batch that has since been restored
  /// or purged.
  Future<String?> submit() async {
    if (!state.canSubmit) return null;

    state = const CardSubmitState(isSubmitting: true);
    try {
      final batchId = await ref.read(deleteCardForUndoUseCaseProvider)(cardId);
      if (!ref.mounted) return batchId;
      state = const CardSubmitState(outcome: SubmitOutcome.savedAndClose);

      return batchId;
    } on Failure catch (failure) {
      if (!ref.mounted) return null;
      state = CardSubmitState(failure: failure);

      return null;
    }
  }

  void reset() => state = const CardSubmitState();
}
