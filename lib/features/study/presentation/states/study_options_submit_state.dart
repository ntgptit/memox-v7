import '../../../../core/error/failure.dart';
import '../../../../core/state/submit_state.dart';
import '../../domain/models/study_card_limit_model.dart';

/// The status of one save on the study options screen.
///
/// A typedef over the shared [SubmitState], like Deck's: the four fields and the
/// policy getters are the same for every form in the app, and what is specific
/// here is only *which problems exist* — a type the domain owns.
typedef StudyOptionsSubmitState = SubmitState<StudyCardLimitProblem>;

/// Which bound the card-limit field broke, if any.
extension StudyOptionsSubmitProblems on StudyOptionsSubmitState {
  StudyCardLimitProblem? get cardLimitProblem =>
      problems.isEmpty ? null : problems.first;
}

/// Maps a failure onto the form.
///
/// **Read out of the failure, never re-derived from the input.** Re-parsing the
/// text here to decide what to show would put the bounds in a second place, and
/// the two would be free to disagree about the same number.
StudyOptionsSubmitState studyOptionsSubmitFailure(Failure failure) {
  if (failure is! ValidationFailure) {
    return StudyOptionsSubmitState(failure: failure);
  }

  final problems = failure.problems.whereType<StudyCardLimitProblem>().toSet();

  return StudyOptionsSubmitState(
    problems: problems,
    failure: problems.isEmpty ? failure : null,
  );
}
