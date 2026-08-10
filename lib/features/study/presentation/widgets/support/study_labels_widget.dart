import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/match_mode.dart';
import '../../../domain/models/study_action_model.dart';
import '../../../domain/models/study_mode.dart';
import '../../../domain/models/study_session_kind_model.dart';
import '../../../domain/models/study_turn_model.dart';

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

  /// What the hint line says once the body has stopped asking (§8.11).
  ///
  /// **Two entries, and `recall` is the one that changed.** `guess` keeps its
  /// answered state up while the learner reads five options to see which was
  /// right. `recall` used to write the moment it resolved and let the next card
  /// follow, so it had nothing to describe — now the back stays up while the
  /// learner says which it was, or while they read a card the clock took, and
  /// "Recall it, then show the answer" is a line about a screen that has moved
  /// on. `fill` still resolves and advances, so it keeps its own sentence and
  /// stays out.
  ///
  /// Null therefore means *keep the mode’s usual hint*, which is what the frame
  /// does with it.
  String? studyModeHintResolved(StudyMode mode) => <StudyMode, String>{
    StudyMode.guess: l10n.studyHintGuessAnswered,
    StudyMode.recall: l10n.studyHintRecallAnswered,
  }[mode];

  /// The glyph that opens the hint line, which is not the same for every mode.
  ///
  /// A check is the default because four of the six hints describe an action the
  /// user performs on the card in front of them. `browse` is the exception: its
  /// hint is about moving between cards, and a check beside "swipe left for
  /// next" reads as a verdict on the card rather than a direction to go in.
  ///
  /// A map keyed by the enum for the same reason [studyModeHint] is one — AD-18
  /// spends the single exhaustive dispatch on the mode in the resolver.
  IconData studyModeHintIcon(StudyMode mode) =>
      <StudyMode, IconData>{
        StudyMode.browse: Icons.keyboard_double_arrow_right,
      }[mode] ??
      Icons.check;

  /// What a mode adds to the frame's context line, if anything.
  ///
  /// A map, and only `match` has an entry — nothing else has a fact the top bar
  /// does not already carry. Null means the line is deck and kind alone, which
  /// is the honest answer rather than a repeated mode name.
  ///
  /// **`match` names its board, and the pairs it counts are that board's**
  /// (BR-156). The top bar already measures the whole round, so repeating the
  /// round's remainder here would say the same thing twice and leave the one
  /// fact the user cannot see anywhere — that finishing these five is not
  /// finishing the round — unsaid.
  String? studyModeContext(
    StudyMode mode, {
    required StudyStageProgressModel progress,
  }) {
    if (mode != StudyMode.match) return null;

    const handler = MatchModeHandler();
    final boards = handler.boardCount(progress.total);
    final index = handler.boardIndexFor(
      done: progress.done,
      cardCount: progress.total,
    );
    final dealt = index * kMatchPairsPerBoard;
    final onBoard = progress.total - dealt < kMatchPairsPerBoard
        ? progress.total - dealt
        : kMatchPairsPerBoard;
    final left = onBoard - (progress.done - dealt);

    return l10n.studyMatchContext(
      progress.round,
      index + 1,
      boards,
      left < 0 ? 0 : left,
    );
  }

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
