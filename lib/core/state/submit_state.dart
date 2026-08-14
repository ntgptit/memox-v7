import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../error/failure.dart';
import 'submit_outcome.dart';

part 'submit_state.freezed.dart';

/// The status of **one** mutation, for any form.
///
/// Deliberately per-operation, not per-screen. A single `isLoading` cannot
/// express "renaming while a delete confirm is open", and the first time two
/// actions overlap the spinner appears on the wrong one — which is why CLAUDE.md
/// names the shared flag as a bug rather than a shortcut.
///
/// **Why this is generic and shared rather than copied per feature.** Deck wrote
/// it once and six controllers used it; Card would have written a second copy of
/// the same four fields and — the part that matters — a second copy of the three
/// getters below. Those getters are the success policy from `SubmitOutcome`, and
/// the policy has already been got wrong once: `canSubmit` was
/// `!isSubmitting && !isDone`, which latched shut on any success and would have
/// let an *add another* form accept exactly one entry. A re-derived policy is a
/// policy that can differ between two features; here there is one copy and the
/// compiler shares it.
///
/// [P] is the form's own problem enum — one value per way a field can be wrong,
/// e.g. `DeckFormProblem.nameEmpty`. It is a `Set` because a form can fail in
/// more than one place at once: creating a root deck with a blank name and no
/// scheduler chosen must mark both, not whichever check ran first.
///
/// Every member is a value or an enum, never a message. The domain says *which*
/// rule failed; the screen picks the ARB copy. That split is what stops a
/// developer-facing database string from reaching a user through a field label.
@freezed
abstract class SubmitState<P extends Enum> with _$SubmitState<P> {
  const factory SubmitState({
    @Default(false) bool isSubmitting,

    /// Every field-level problem the last attempt found.
    ///
    /// `Set` rather than a list: the same problem cannot be present twice, and
    /// order carries no meaning — a form renders each error next to its own
    /// field.
    @Default(<Never>{}) Set<P> problems,

    /// The failure that ended the last attempt, when it was not a field problem.
    /// Held as the domain type so the screen chooses the copy.
    Failure? failure,

    /// Set once the operation has succeeded, so a screen reacts exactly once
    /// instead of on every rebuild.
    ///
    /// Carries *which kind* of success it was: only [SubmitOutcome.savedAndClose]
    /// closes anything. A form that stays open for the next entry reports
    /// [SubmitOutcome.savedAndContinue] and clears its own draft — see the enum
    /// for why a boolean could not express this.
    SubmitOutcome? outcome,
  }) = _SubmitState<P>;

  const SubmitState._();

  /// Whether a tap should be accepted at all — the double-submit guard.
  ///
  /// A `savedAndContinue` success deliberately leaves this true: the editor is
  /// still open and the next entry must be submittable without anything having to
  /// call reset first. Only `savedAndClose` latches it shut, and only because the
  /// form is on its way out.
  bool get canSubmit => !isSubmitting && outcome != SubmitOutcome.savedAndClose;

  /// True on the transition a widget should close on.
  bool get shouldClose => outcome == SubmitOutcome.savedAndClose;

  /// True on the transition a widget should clear its draft on.
  bool get shouldClearDraft => outcome == SubmitOutcome.savedAndContinue;

  /// Whether the last attempt failed on a field rather than on the write.
  bool get hasProblem => problems.isNotEmpty;

  /// The first of [candidates] present, or null.
  ///
  /// For a field with more than one way to be wrong: a name can be empty *or*
  /// too long, and the input shows one error at a time. The feature owns which
  /// values belong to which field — see the accessors a feature defines beside
  /// its problem enum.
  P? firstProblemOf(Set<P> candidates) =>
      problems.firstWhereOrNull(candidates.contains);
}

/// Turns a [Failure] into the state a form should show.
///
/// **Read out of the failure, never re-derived from the input.** Re-parsing the
/// submitted value here to decide what to mark would put the rule in a second
/// place, and the two would be free to disagree about the same number.
///
/// A `ValidationFailure` carrying no problem of type [P] is a real case, not a
/// defensive branch: the domain can reject input for a reason this form has no
/// field for. It keeps the failure so the screen still says something, rather
/// than reporting a clean state after a rejected write.
///
/// Generic and shared for the same reason [SubmitState] is: the mapping is one
/// policy, and a per-feature copy is a policy that can differ per feature.
SubmitState<P> submitStateFromFailure<P extends Enum>(Failure failure) {
  if (failure is! ValidationFailure) return SubmitState<P>(failure: failure);

  final problems = failure.problems.whereType<P>().toSet();

  return SubmitState<P>(
    problems: problems,
    failure: problems.isEmpty ? failure : null,
  );
}
