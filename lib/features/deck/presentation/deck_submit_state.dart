import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/failure.dart';
import '../../../core/state/submit_outcome.dart';
import '../domain/deck_entity.dart';

part 'deck_submit_state.freezed.dart';

/// The status of **one** deck mutation.
///
/// Deliberately per-operation. A single `isLoading` on a screen cannot express
/// "renaming while a delete confirm is open", and the first time two actions
/// overlap the spinner appears on the wrong one — which is why CLAUDE.md names
/// the shared flag as a bug rather than a shortcut.
///
/// Every field is a value or an enum, never a message. The domain says *which*
/// rule failed; the screen picks the ARB copy. That split is what stops a
/// developer-facing database error string from reaching a user through a field
/// label.
@freezed
abstract class DeckSubmitState with _$DeckSubmitState {
  const factory DeckSubmitState({
    @Default(false) bool isSubmitting,

    /// Which BR-01 rule the name breaks, if any.
    DeckNameProblem? nameProblem,

    /// True when the mandatory scheduler choice is still missing (BR-11).
    /// Only ever set by the create-root flow; nothing else offers the choice.
    @Default(false) bool isSchedulerMissing,

    /// The failure that ended the last attempt, when it was not a field
    /// problem. Held as the domain type so the screen chooses the copy.
    Failure? failure,

    /// Set once the operation has succeeded, so a screen reacts exactly once
    /// instead of on every rebuild.
    ///
    /// Carries *which kind* of success it was: only [SubmitOutcome.savedAndClose]
    /// closes anything. A form that stays open for the next entry reports
    /// [SubmitOutcome.savedAndContinue], and the widget clears its own draft —
    /// see the enum for why a boolean could not express this.
    SubmitOutcome? outcome,
  }) = _DeckSubmitState;

  const DeckSubmitState._();

  /// Whether a tap should be accepted at all — the double-submit guard.
  ///
  /// A `savedAndContinue` success deliberately leaves this true: the editor is
  /// still open and the next entry must be submittable without anything having to
  /// call [reset] first. Only `savedAndClose` latches it shut, and only because
  /// the form is on its way out.
  bool get canSubmit => !isSubmitting && outcome != SubmitOutcome.savedAndClose;

  /// True on the transition a widget should close on.
  bool get shouldClose => outcome == SubmitOutcome.savedAndClose;

  /// True on the transition a widget should clear its draft on.
  bool get shouldClearDraft => outcome == SubmitOutcome.savedAndContinue;

  bool get hasFieldError => nameProblem != null || isSchedulerMissing;
}

/// Maps a repository failure onto the form.
///
/// A `ValidationFailure` naming the `name` field lands on [nameProblem] so it
/// renders under the input; anything else lands on [failure] so it renders
/// where the operation lives. Without the split, "name is required" arrives as
/// a banner and the field the user must fix is not marked at all.
///
/// The repository's own name check runs `DeckEntity.nameProblem` too, so a
/// validation failure that got past the form can only mean the form and the
/// rule disagreed — the mapping below re-derives the problem from the input
/// rather than trusting the failure's non-localized text.
DeckSubmitState deckSubmitFailure(Failure failure, {String? name}) {
  if (failure is! ValidationFailure) return DeckSubmitState(failure: failure);

  final problem = name == null ? null : DeckEntity.nameProblem(name);

  return DeckSubmitState(
    nameProblem: problem,
    isSchedulerMissing: failure.fieldErrors.containsKey('schedulerType'),
    // Keep the failure when the field mapping found nothing to point at, so a
    // validation error can never end as a silent no-op.
    failure:
        problem == null && !failure.fieldErrors.containsKey('schedulerType')
        ? failure
        : null,
  );
}
