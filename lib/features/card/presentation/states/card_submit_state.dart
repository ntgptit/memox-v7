import '../../../../core/error/failure.dart';
import '../../../../core/state/submit_state.dart';
import '../../domain/failures/card_validation_failure.dart';

/// The status of **one** card mutation.
///
/// A typedef over the shared [SubmitState], exactly like `DeckSubmitState`: the
/// four fields and the policy getters live once in core, and what is Card's is
/// only which problems exist — [CardValidationProblem], owned by the domain.
typedef CardSubmitState = SubmitState<CardValidationProblem>;

/// Card's own reading of the problem set, so a widget asks `state.frontProblem`
/// rather than filtering the set at each call site.
extension CardSubmitProblems on CardSubmitState {
  CardValidationProblem? get frontProblem => firstProblemOf(kCardFrontProblems);

  CardValidationProblem? get backProblem => firstProblemOf(kCardBackProblems);
}

/// Maps a repository or use-case failure onto the form.
///
/// **The problems are read out of the failure, not re-derived from the input** —
/// the same discipline `deckSubmitFailure` documents. `parseCardSides` has
/// already put the typed problems in the failure; this only sorts them so a
/// field problem renders under its input and anything else renders where the
/// operation lives.
CardSubmitState cardSubmitFailure(Failure failure) {
  if (failure is! ValidationFailure) return CardSubmitState(failure: failure);

  final problems = failure.problems.whereType<CardValidationProblem>().toSet();

  return CardSubmitState(
    problems: problems,
    failure: problems.isEmpty ? failure : null,
  );
}
