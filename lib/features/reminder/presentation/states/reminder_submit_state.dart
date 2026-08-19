import '../../../../core/error/failure.dart';
import '../../../../core/state/submit_state.dart';
import '../../domain/failures/reminder_failure.dart';

/// The status of one reminder command — **not** the screen's data (UC-17).
///
/// **A typedef over the shared [SubmitState], like Deck's and Study's.** The
/// four fields and the double-submit policy are the same for every mutation in
/// the app; what is specific here is only *which rejections exist*, and that is
/// a type the domain owns. A bespoke state class was written first and was
/// wrong for the reason `SubmitState` exists: a re-derived `canSubmit` is a
/// policy that can differ between two features.
///
/// **Task status and data are separate objects on purpose.** The stored settings
/// arrive from their own stream, so a failed enable does not blank the toggle
/// and a re-emission of the row does not clear a banner the user has not read.
typedef ReminderSubmitState = SubmitState<ReminderSetupRejection>;

/// Why the last command did not complete, if it did not.
///
/// A `Set` in [SubmitState] because a form can fail in two places at once; a
/// reminder command cannot, so the one value is read off the front. `null` means
/// there is nothing to show.
extension ReminderSubmitProblems on ReminderSubmitState {
  ReminderSetupRejection? get rejection =>
      problems.isEmpty ? null : problems.first;
}

/// Maps a failure onto the screen.
///
/// **Read off the failure, never inferred from the type.** Every throw in this
/// feature attaches a [ReminderSetupRejection]; a failure arriving without one
/// falls back to the schedule rejection, which is the one that offers a retry —
/// an unlabelled failure the user can retry beats a banner with no way out.
ReminderSubmitState reminderSubmitFailure(Failure failure) {
  final reason = failure.reason;

  return ReminderSubmitState(
    problems: <ReminderSetupRejection>{
      reason is ReminderSetupRejection
          ? reason
          : ReminderSetupRejection.scheduleFailed,
    },
  );
}
