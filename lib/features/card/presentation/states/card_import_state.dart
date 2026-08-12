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
