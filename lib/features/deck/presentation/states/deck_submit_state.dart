import '../../../../core/error/failure.dart';
import '../../../../core/state/submit_state.dart';
import '../../domain/failures/deck_validation_failure.dart';

/// The status of **one** deck mutation.
///
/// A typedef, not a subclass: the four fields and the three policy getters are
/// the same for every form in the app and live once, in [SubmitState]. What is
/// specific to Deck is only *which problems exist*, which is the type argument —
/// and that type is [DeckValidationProblem], owned by the domain. Presentation
/// used to declare its own parallel enum and convert between the two, and the
/// conversion re-ran the rule to decide which value to produce.
typedef DeckSubmitState = SubmitState<DeckValidationProblem>;

/// Deck's own reading of the problem set.
///
/// These exist so a widget asks `state.nameProblem` rather than filtering the set
/// at each call site. The generic state made the storage shared; this keeps the
/// questions specific.
extension DeckSubmitProblems on DeckSubmitState {
  /// Which name rule the last attempt broke, if any.
  DeckValidationProblem? get nameProblem => firstProblemOf(kDeckNameProblems);

  bool get isSchedulerMissing =>
      problems.contains(DeckValidationProblem.schedulerMissing);
}

/// Maps a repository or use-case failure onto the form.
///
/// **The problems are read out of the failure, not re-derived from the input.**
/// This function used to take the raw name and run the domain rule again to work
/// out which field to mark, which made presentation a third owner of BR-01. The
/// failure now carries the typed problems, so this only sorts them: field problems
/// render under their input, anything else renders where the operation lives.
///
/// A `ValidationFailure` whose problems are not Deck's — impossible today, but the
/// set is typed `Set<Enum>` in `core/` — keeps the failure rather than silently
/// producing an empty form state.
DeckSubmitState deckSubmitFailure(Failure failure) {
  if (failure is! ValidationFailure) return DeckSubmitState(failure: failure);

  final problems = failure.problems.whereType<DeckValidationProblem>().toSet();

  return DeckSubmitState(
    problems: problems,
    // Keep the failure when nothing in it points at a field, so a validation
    // error can never end as a silent no-op.
    failure: problems.isEmpty ? failure : null,
  );
}
