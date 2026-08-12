import '../../../../core/error/failure.dart';
import '../../domain/models/card_import_result_model.dart';
import '../../domain/models/card_transfer_source_model.dart';

/// The wizard's three steps (UC-10, wireframe M4.12). Order is the enum's
/// order; the stepper prints `index + 1` of 3.
enum CardImportStep { source, preview, confirm }

/// Which source panel step 1 shows (UC-10 step 2 / A1).
enum CardImportSourceKind { upload, paste }

/// What the last file pick left behind: a file, a typed refusal, or nothing
/// yet. One value with two facets rather than two providers, because they
/// replace each other — a successful pick clears the refusal and a refusal
/// keeps the previous file (UC-10 A5, E1).
final class CardImportFilePick {
  const CardImportFilePick({this.file, this.failure});

  final CardTransferFileSource? file;

  /// The refusal of the *last attempt* — an unsupported extension, mostly.
  /// The previous [file] survives it, so a failed replace does not cost the
  /// user their working source.
  final Failure? failure;

  CardImportFilePick withFile(CardTransferFileSource next) =>
      CardImportFilePick(file: next);

  CardImportFilePick withFailure(Failure next) =>
      CardImportFilePick(file: file, failure: next);
}

/// The commit's own submit state (UC-10 steps 6–8).
///
/// Not the shared `SubmitState`: a commit's success carries a payload — the
/// counts the result view prints — and the shared type deliberately has no
/// slot for one. The same three-phase policy applies: submitting locks the
/// button, a failure keeps everything (UC-10 E5), and a result latches the
/// step into its result view.
final class CardImportSubmitState {
  const CardImportSubmitState({
    this.isSubmitting = false,
    this.failure,
    this.result,
  });

  final bool isSubmitting;
  final Failure? failure;
  final CardImportResult? result;

  /// The double-submit guard: one in flight, or already done, means no.
  bool get canSubmit => !isSubmitting && result == null;

  bool get isDone => result != null;
}

/// The wizard's presentation phase (M4.12 states 1–8): which face the screen,
/// the stepper and the action bar all show right now.
///
/// **Derived, never stored.** [CardImportStep] stays the only navigation
/// state; this classification is computed fresh each build from the step, the
/// parse, the mapping and the commit — a sealed answer to "what is on
/// screen", replacing the boolean soup that would otherwise be re-derived,
/// slightly differently, in every widget.
enum CardImportPhase {
  /// Step 1, with or without a chosen source.
  source,

  /// Step 2 mounted and the decode still running (state 2).
  parsing,

  /// Step 2 with rows on screen — classified, mapped or waiting on mapping.
  preview,

  /// Step 3, nothing committed yet (the Confirm face).
  confirm,

  /// The one transaction is in flight (state 5).
  submitting,

  /// Wrote everything it meant to: no invalid rows, no duplicates skipped.
  completed,

  /// Wrote some and skipped some (state 7).
  completedWithSkips,

  /// The transaction succeeded but the in-transaction recheck skipped every
  /// row — not a failure, and never presented as one (BR-170).
  noCardsAdded,

  /// The transaction failed and rolled back; the draft is intact (state 8).
  commitFailure;

  /// True for the four faces that replace the wizard chrome with an outcome
  /// (states 6–8): the app bar retitles and the breadcrumb, context chip and
  /// stepper leave so the hero is the focal point.
  bool get isOutcome => switch (this) {
    CardImportPhase.completed ||
    CardImportPhase.completedWithSkips ||
    CardImportPhase.noCardsAdded ||
    CardImportPhase.commitFailure => true,
    _ => false,
  };
}

/// The one place the classification is computed, so every widget agrees.
///
/// [invalidCount] comes from the preview (the commit never saw those rows);
/// the skip decision inside [submit]'s result comes from the transaction's
/// own recheck — the two sources the result faces are required to keep apart.
CardImportPhase deriveCardImportPhase({
  required CardImportStep step,
  required bool isParsing,
  required CardImportSubmitState submit,
  required int invalidCount,
}) {
  final result = submit.result;
  if (result != null) {
    if (result.imported == 0) return CardImportPhase.noCardsAdded;
    if (invalidCount > 0 || result.duplicatesSkipped > 0) {
      return CardImportPhase.completedWithSkips;
    }

    return CardImportPhase.completed;
  }
  if (submit.isSubmitting) return CardImportPhase.submitting;
  if (submit.failure != null) return CardImportPhase.commitFailure;

  return switch (step) {
    CardImportStep.source => CardImportPhase.source,
    CardImportStep.preview =>
      isParsing ? CardImportPhase.parsing : CardImportPhase.preview,
    CardImportStep.confirm => CardImportPhase.confirm,
  };
}
