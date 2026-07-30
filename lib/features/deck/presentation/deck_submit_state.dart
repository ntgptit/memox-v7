import '../../../core/error/failure.dart';
import '../../../core/state/submit_state.dart';
import '../domain/deck_entity.dart';

/// Every way a deck form can be wrong, one value per field-and-reason.
///
/// A flat enum rather than one nullable field per input: the state that holds
/// these is [SubmitState], shared with every other feature, and it cannot carry a
/// field named after Deck's inputs. What it carries is a `Set<DeckFormProblem>`,
/// which is also what lets a single attempt report a blank name *and* a missing
/// scheduler — the create-root form can fail both checks at once, and marking
/// only the first one found would send the user round twice.
///
/// The name values mirror `DeckNameProblem` (BR-01), which stays the domain type:
/// `DeckEntity.nameProblem` is the rule, this is how the form spells it.
enum DeckFormProblem {
  nameEmpty,
  nameTooLong,

  /// The mandatory scheduler choice is still missing (BR-11). Only the
  /// create-root flow can produce it; nothing else offers the choice.
  schedulerMissing,
}

/// The values that belong to the name input.
///
/// Named because two places need the same answer — the accessor below and any
/// future test asserting the grouping — and a second literal set is how the two
/// drift apart.
const Set<DeckFormProblem> kDeckNameProblems = <DeckFormProblem>{
  DeckFormProblem.nameEmpty,
  DeckFormProblem.nameTooLong,
};

/// The status of **one** deck mutation.
///
/// A typedef, not a subclass: the four fields and the three policy getters are
/// the same for every form in the app and live once, in [SubmitState]. What is
/// specific to Deck is only *which problems exist*, which is the type argument.
typedef DeckSubmitState = SubmitState<DeckFormProblem>;

/// Deck's own reading of the problem set.
///
/// These exist so a widget asks `state.nameProblem` rather than reaching into the
/// set with a filter at each call site. The generic state made the storage
/// shared; this keeps the questions specific.
extension DeckSubmitProblems on DeckSubmitState {
  /// Which name rule the last attempt broke, if any.
  DeckFormProblem? get nameProblem => firstProblemOf(kDeckNameProblems);

  bool get isSchedulerMissing =>
      problems.contains(DeckFormProblem.schedulerMissing);
}

/// How the domain's name rule is spelled as a form problem.
///
/// One switch, in one place. Exhaustive over [DeckNameProblem], so a third name
/// rule added to BR-01 fails to compile here rather than silently arriving with
/// no error text.
DeckFormProblem? deckNameFormProblem(String name) =>
    switch (DeckEntity.nameProblem(name)) {
      DeckNameProblem.empty => DeckFormProblem.nameEmpty,
      DeckNameProblem.tooLong => DeckFormProblem.nameTooLong,
      null => null,
    };

/// Maps a repository failure onto the form.
///
/// A `ValidationFailure` naming a field lands in [SubmitState.problems] so it
/// renders under the input; anything else lands on [SubmitState.failure] so it
/// renders where the operation lives. Without the split, "name is required"
/// arrives as a banner and the field the user must fix is not marked at all.
///
/// The repository's own name check runs `DeckEntity.nameProblem` too, so a
/// validation failure that got past the form can only mean the form and the rule
/// disagreed — this re-derives the problem from the input rather than trusting the
/// failure's non-localized text.
DeckSubmitState deckSubmitFailure(Failure failure, {String? name}) {
  if (failure is! ValidationFailure) return DeckSubmitState(failure: failure);

  final problems = <DeckFormProblem>{
    if (name != null) ?deckNameFormProblem(name),
    if (failure.fieldErrors.containsKey('schedulerType'))
      DeckFormProblem.schedulerMissing,
  };

  return DeckSubmitState(
    problems: problems,
    // Keep the failure when the field mapping found nothing to point at, so a
    // validation error can never end as a silent no-op.
    failure: problems.isEmpty ? failure : null,
  );
}
