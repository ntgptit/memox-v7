import '../../../../core/error/failure.dart';
import '../../../../core/state/submit_state.dart';
import '../../../study/domain/models/study_card_limit_model.dart';

/// The status of **one** save on the settings screen.
///
/// **One type, four controllers** — the shape Deck settled on: a feature has one
/// problem enum and every one of its write controllers is parameterised by it,
/// even the ones that cannot produce a problem. Appearance, language and reset
/// never populate `problems`; the alternative was a second submit type whose
/// only difference is an enum nobody can name.
///
/// **The enum is Study's, not a copy.** The card limit's bounds and its three
/// ways of being wrong belong to `StudyCardLimit`, and BR-183 requires exactly
/// one copy of them — this screen and the deck's own options screen edit the
/// same number and must reject the same values.
typedef SettingsSubmitState = SubmitState<StudyCardLimitProblem>;

/// Which bound the card-limit field broke, if any.
extension SettingsSubmitProblems on SettingsSubmitState {
  StudyCardLimitProblem? get cardLimitProblem =>
      problems.isEmpty ? null : problems.first;
}

/// Maps a failure onto the form. The policy lives in `core/state/`.
SettingsSubmitState settingsSubmitFailure(Failure failure) =>
    submitStateFromFailure<StudyCardLimitProblem>(failure);
