import '../../../../core/error/failure.dart';
import '../../../../core/state/submit_state.dart';
import '../../domain/failures/tag_validation_failure.dart';

/// The status of **one** add-tag attempt.
///
/// A typedef over the shared [SubmitState], exactly like `CardSubmitState`: the
/// four fields and the policy getters live once in core, and what is the tag
/// entry's own is only which problems exist — [TagValidationProblem].
typedef CardTagState = SubmitState<TagValidationProblem>;

/// The tag field's reading of the problem set. All three problems belong to the
/// one input, so there is a single accessor rather than a per-field split.
extension CardTagProblems on CardTagState {
  TagValidationProblem? get problem =>
      firstProblemOf(TagValidationProblem.values.toSet());
}

/// Maps a repository or use-case failure onto the tag field.
///
/// The problems are read out of the failure, not re-derived — the discipline
/// `cardSubmitFailure` documents. `AddCardTagUseCase` and the repository put the
/// typed problems in the failure; this only routes a field problem under the
/// input and anything else to the operation.
CardTagState cardTagFailure(Failure failure) {
  if (failure is! ValidationFailure) return CardTagState(failure: failure);

  final problems = failure.problems.whereType<TagValidationProblem>().toSet();

  return CardTagState(
    problems: problems,
    failure: problems.isEmpty ? failure : null,
  );
}
