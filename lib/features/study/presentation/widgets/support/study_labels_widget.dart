import 'package:flutter/widgets.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/study_action_model.dart';
import '../../../domain/models/study_mode.dart';
import '../../../domain/models/study_session_kind_model.dart';

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

  /// The one-line instruction at the bottom of the session frame.
  ///
  /// A map for the same reason [studyMode] is one, and there is no fallback
  /// sentence: a mode with no hint gets an empty line rather than another mode's
  /// instruction, which would tell the user to do something this screen cannot
  /// do. The empty line is visible in the widget test, and the wrong sentence
  /// would not be.
  String? studyModeHint(StudyMode mode) => <StudyMode, String>{
    StudyMode.browse: l10n.studyHintBrowse,
    StudyMode.selfAssess: l10n.studyHintSelfAssess,
    StudyMode.match: l10n.studyHintMatch,
    StudyMode.guess: l10n.studyHintGuess,
    StudyMode.recall: l10n.studyHintRecall,
    StudyMode.fill: l10n.studyHintFill,
  }[mode];

  /// What a mode adds to the frame's context line, if anything.
  ///
  /// A map, and only `match` has an entry — nothing else has a fact the top bar
  /// does not already carry. Null means the line is deck and kind alone, which
  /// is the honest answer rather than a repeated mode name.
  String? studyModeContext(
    StudyMode mode, {
    required int round,
    required int remaining,
  }) => <StudyMode, String>{
    StudyMode.match: l10n.studyMatchContext(round, remaining),
  }[mode];

  /// Which of the two card sets this session is working through (BR-142).
  String studySessionKind(StudySessionKind kind) => switch (kind) {
    StudySessionKind.learning => l10n.studyKindLearning,
    StudySessionKind.reviewing => l10n.studyKindReviewing,
  };

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
