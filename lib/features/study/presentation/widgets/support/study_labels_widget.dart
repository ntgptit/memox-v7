import 'package:flutter/widgets.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/study_action_model.dart';
import '../../../domain/models/study_mode.dart';

/// Copy for the Study vocabulary, in one place.
///
/// **The switch here is over `StudyAction`, not `StudyMode`.** AD-18 allows one
/// exhaustive dispatch on the mode and it belongs to the resolver, so mode names
/// are looked up through a map rather than branched on — a second `switch` in
/// `presentation/` is exactly what the guard rule forbids.
///
/// The label is display only. What reaches the database is the canonical value
/// (BR-132), so renaming a button never rewrites history.
extension StudyLabels on BuildContext {
  /// The button text for an action of either algorithm (BR-30).
  String studyAction(StudyAction action) => switch (action) {
    StudyAction.forgotten => l10n.studyActionForgotten,
    StudyAction.remembered => l10n.studyActionRemembered,
    StudyAction.again => l10n.studyActionAgain,
    StudyAction.hard => l10n.studyActionHard,
    StudyAction.good => l10n.studyActionGood,
    StudyAction.easy => l10n.studyActionEasy,
  };

  /// The name of a mode, for the chooser and the session header.
  ///
  /// A map keyed by the enum rather than a `switch`: it reads the same and it
  /// keeps the single-dispatch rule intact. A mode with no entry falls back to
  /// its stored value, which is a name nobody wants to see and therefore an
  /// obvious sign the map is missing one.
  String studyMode(StudyMode mode) =>
      <StudyMode, String>{
        StudyMode.browse: l10n.studyModeBrowse,
        StudyMode.selfAssess: l10n.studyModeSelfAssess,
        StudyMode.match: l10n.studyModeMatch,
        StudyMode.guess: l10n.studyModeGuess,
        StudyMode.recall: l10n.studyModeRecall,
        StudyMode.fill: l10n.studyModeFill,
      }[mode] ??
      mode.name;

  /// Why a mode is offered but cannot run (BR-99).
  ///
  /// Never null for a mode that is disabled: BR-99 says the reason is shown, not
  /// that the mode disappears — a control that vanishes reads as a bug.
  String studyModeUnavailable(StudyMode mode) =>
      <StudyMode, String>{
        StudyMode.fill: l10n.studyModeNeedsExample,
        StudyMode.guess: l10n.studyModeNeedsMeanings,
        StudyMode.match: l10n.studyModeNeedsPairs,
      }[mode] ??
      l10n.studyNothingDueMessage;
}
