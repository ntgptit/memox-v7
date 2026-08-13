import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../di/card_export_use_case_provider.dart';
import '../../domain/models/card_export_request_model.dart';
import '../states/card_export_state.dart';

part 'card_export_controller.g.dart';

/// The export command (UC-11 steps 4–7): one hand-off, its own submit state,
/// nothing else — the shape `CommitCardImport` established for this feature.
///
/// **It composes nothing.** Reading a snapshot, encoding it, naming the file
/// and handing it to the OS is one interaction and lives in one use case; a
/// controller that ordered those four steps would put a business flow in
/// presentation, and Retry (UC-11 E2…E4) would then have to repeat that
/// ordering correctly a second time.
///
/// **It also holds no scope and no format.** The sheet owns both, which is
/// what makes a failure keep them for free: this state going back to a failure
/// does not disturb a request the user is still looking at.
///
/// Keyed by deck: two decks' sheets cannot be open at once today, but the key
/// is what keeps a stale state from one deck arriving in another's sheet.
@riverpod
class ExportCards extends _$ExportCards {
  /// Whether the user has left the export behind (UC-11 A5, M4.13 W4).
  ///
  /// **Not part of the state.** Nothing renders it — it is read once, deep
  /// inside a use case that has already started, and a rebuild is exactly what
  /// must *not* happen when it flips. Putting it in [CardExportSubmitState]
  /// would also make it survive into the next `submit`, which is the opposite
  /// of what it means.
  bool _isCancelled = false;

  @override
  CardExportSubmitState build(String deckId) {
    // The sheet leaves by three doors and only one of them is a button:
    // `Cancel` calls [cancel] directly, while Android Back and the drag-down
    // gesture pop the route without telling this notifier anything. All three
    // end with the sheet no longer watching, so disposal is the one signal
    // that catches every route — and it is why there is no `PopScope` here.
    // Blocking the pop would contradict W4, which wants Back to close the
    // sheet; what W4 forbids is the *file*, not the exit.
    ref.onDispose(() => _isCancelled = true);

    return const CardExportSubmitState();
  }

  /// Runs one export. A second press while the first is in flight does
  /// nothing (UC-11 A4) — the latch is [CardExportSubmitState.canSubmit], and
  /// it is checked here rather than only by disabling the button, because a
  /// disabled button is a rendering fact and this is the rule.
  Future<void> submit(CardExportRequest request) async {
    if (!state.canSubmit) return;

    _isCancelled = false;
    state = const CardExportSubmitState(isSubmitting: true);
    try {
      final result = await ref.read(exportCardsUseCaseProvider)(
        request,
        isCancelled: () => _isCancelled,
      );
      if (!ref.mounted) return;
      state = CardExportSubmitState(result: result);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = CardExportSubmitState(failure: failure);
    } on Object catch (error, stackTrace) {
      // **Not swallowed, and not left in flight either.** Everything below
      // this maps its own errors to a `Failure`, so reaching here means a bug
      // rather than a known outcome — but the old shape let such an error
      // escape the `try` with `isSubmitting` still true, which locks the
      // primary action and shows no reason, leaving the sheet with no way
      // forward at all. The state is settled first so the UI can recover, then
      // the error travels on to the zone that owns crash reporting.
      if (ref.mounted) {
        state = CardExportSubmitState(
          failure: UnknownFailure(
            message: 'The export could not be completed.',
            cause: error,
          ),
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// The user gave up on an export that is already running (M4.13 W4).
  ///
  /// Only stops the hand-off — there is nothing else to stop, because a read
  /// that writes nothing (BR-178) and an encode that touches no file leave
  /// nothing behind when they finish unheeded.
  void cancel() => _isCancelled = true;

  /// Back to idle. Called when the sheet opens, so a reopened sheet never
  /// wears the previous attempt's outcome.
  void reset() {
    _isCancelled = false;
    state = const CardExportSubmitState();
  }
}
