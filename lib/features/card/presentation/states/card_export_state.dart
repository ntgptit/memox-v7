import '../../../../core/error/failure.dart';
import '../../domain/failures/card_export_failure.dart';
import '../../domain/models/card_export_result_model.dart';

/// The export command's own submit state (UC-11 steps 3–7).
///
/// **Its own, and not the card list's.** The list already streams rows and
/// counts behind the sheet; hanging the export's spinner on that screen's
/// `isLoading` would grey a list the export never touches (BR-178) and make
/// two unrelated operations share one flag.
///
/// Three slots and no more: whether one hand-off is in flight, why the last
/// one failed, and how the last one ended. The chosen scope and format are not
/// here — they belong to the sheet, which keeps them across a failure so Retry
/// repeats the same request (UC-11 E2…E4, M4.13 E8).
final class CardExportSubmitState {
  const CardExportSubmitState({
    this.isSubmitting = false,
    this.failure,
    this.result,
  });

  final bool isSubmitting;
  final Failure? failure;
  final CardExportResult? result;

  /// The double-submit latch (UC-11 A4).
  ///
  /// **A dismissed share sheet is still submittable.** Dismissal is a cancel,
  /// not an outcome to latch on (BR-181): the user closed the OS sheet and may
  /// well press Export again. Only [CardExportResult.shared] ends the sheet,
  /// and a failure deliberately leaves this true so Retry works.
  bool get canSubmit => !isSubmitting && result != CardExportResult.shared;
}

/// Which face the export sheet is showing (M4.13 W3).
///
/// **Derived, never stored** — the same rule `CardImportPhase` follows. The
/// body and the action row both read this one value, so the two cannot end up
/// disagreeing about whether an export is running.
///
/// Five values for seven states because two pairs collapse honestly: the
/// wireframe's *dismissed* is initial by definition (BR-181), and its
/// *unavailable / platform error* and *repository / encoder failure* differ
/// only in the sentence they print, which the copy switch owns.
enum CardExportPhase {
  /// Scope and format on screen, primary armed. Also where a dismissed share
  /// sheet lands: no error, no confirmation, the format still chosen (E5).
  initial,

  /// The file is being read, encoded and handed over. The action panel is
  /// replaced in place; the body does not move (E7).
  generating,

  /// The OS accepted the file. The sheet closes and the card list confirms —
  /// truthfully, without claiming a save location (E9, BR-181).
  shared,

  /// A failure the same request can be retried against: a failed read, a
  /// failed encode, no share sheet, or a platform channel that threw. Scope
  /// and format survive it (E8).
  retryableError,

  /// The scope itself is gone — an emptied deck, a deleted deck, or a selected
  /// id that no longer belongs here. There is nothing to retry until the user
  /// picks again, so the primary is hidden rather than disabled (W3 state 7).
  invalidScope,
}

/// The typed reason behind a failure, or null when it carries none.
///
/// One reader for both slots `CardExportProblem` travels in — `problems` on a
/// `ValidationFailure`, `reason` on the rest — so the phase and the copy can
/// never classify the same failure differently.
CardExportProblem? cardExportProblemOf(Failure failure) {
  if (failure is ValidationFailure) {
    return failure.problems.whereType<CardExportProblem>().firstOrNull;
  }
  final reason = failure.reason;

  return reason is CardExportProblem ? reason : null;
}

/// Whether [problem] means the scope is no longer exportable at all.
///
/// Exhaustive on purpose: a new problem value must fail to compile here rather
/// than silently default into the retryable half and offer a Try again that
/// cannot succeed.
bool isCardExportScopeProblem(CardExportProblem? problem) => switch (problem) {
  CardExportProblem.emptyScope ||
  CardExportProblem.staleSelection ||
  CardExportProblem.deckMissing => true,
  CardExportProblem.readFailed ||
  CardExportProblem.encodeFailed ||
  CardExportProblem.shareUnavailable ||
  CardExportProblem.sharePlatformError ||
  null => false,
};

/// The one place the sheet's face is decided.
CardExportPhase deriveCardExportPhase(CardExportSubmitState submit) {
  if (submit.result == CardExportResult.shared) return CardExportPhase.shared;
  if (submit.isSubmitting) return CardExportPhase.generating;

  final failure = submit.failure;
  if (failure != null) {
    return isCardExportScopeProblem(cardExportProblemOf(failure))
        ? CardExportPhase.invalidScope
        : CardExportPhase.retryableError;
  }

  // Covers both "nothing tried yet" and "the share sheet was dismissed".
  return CardExportPhase.initial;
}
