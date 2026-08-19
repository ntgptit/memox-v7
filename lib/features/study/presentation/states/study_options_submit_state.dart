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
/// **The mapping itself is `core/state/submit_state.dart`'s**, and was moved
/// there when Settings needed the identical function for the identical enum
/// (M99.28). This name stays because it reads better at the call sites than the
/// generic one and because the type argument is the only thing specific to this
/// form.
StudyOptionsSubmitState studyOptionsSubmitFailure(Failure failure) =>
    submitStateFromFailure<StudyCardLimitProblem>(failure);
