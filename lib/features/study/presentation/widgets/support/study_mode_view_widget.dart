import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../../domain/models/guess_mode.dart';
import '../../../domain/models/match_mode.dart';
import '../../../domain/models/recall_mode.dart';
import '../../../domain/models/study_action_model.dart';
import '../../../domain/models/study_mode.dart';
import '../../../domain/models/study_scheduler.dart';
import '../../../domain/models/study_outcome_reason_model.dart';
import '../../../domain/models/study_turn_model.dart';
import '../../states/study_session_state.dart';
import '../sections/fill_answer_section_widget.dart';
import '../sections/guess_question_section_widget.dart';
import '../sections/match_board_section_widget.dart';
import '../sections/recall_timer_section_widget.dart';
import '../sections/study_card_face_section_widget.dart';

/// What the session screen tells a mode's widget when an answer arrives.
typedef StudyAnswerSink =
    void Function(
      StudyAction action, {
      StudyOutcomeReason? outcomeReason,
      int? comparisonVersion,
      bool? hasUsedHint,
    });

/// Builds the body for whichever stage is running.
///
/// **A `Map`, not a `switch`.** AD-18 allows exactly one exhaustive branch on
/// `StudyMode` and it lives in `study_mode.dart`; a second one here would be a
/// mode's presentation leaking out of its own file, which is the thing the guard
/// rule exists to stop. `study_labels_widget.dart` already does it this way.
///
/// A handler cannot return the widget either — handlers are `domain/`, and
/// `domain/` may not know Flutter. So the mapping lives here, in the layer that
/// is allowed to know both.
Widget? studyModeView({
  required StudyMode mode,
  required StudySessionState state,
  required StudyAnswerSink onAnswer,
  required VoidCallback onContinue,
  required Random random,
}) {
  final turn = state.turn;
  if (turn == null) return null;

  final builders = <StudyMode, Widget Function()>{
    StudyMode.browse: () => StudyCardFaceSectionWidget(
      turn: turn,
      // `browse` produces no action at all (BR-111), so it gets no buttons and
      // one way forward.
      actions: const <StudyAction>[],
      onAction: (_) {},
      onContinue: onContinue,
      shouldShowBackImmediately: true,
      isLocked: state.isSubmitting,
    ),
    StudyMode.selfAssess: () => StudyCardFaceSectionWidget(
      turn: turn,
      actions: state.actions,
      onAction: onAnswer,
      onContinue: onContinue,
      isLocked: state.isSubmitting,
    ),
    StudyMode.match: () => _matchView(
      turn: turn,
      state: state,
      onAnswer: onAnswer,
      random: random,
    ),
    StudyMode.guess: () => _guessView(
      turn: turn,
      state: state,
      onAnswer: onAnswer,
      random: random,
    ),
    StudyMode.recall: () => RecallTimerSectionWidget(
      turn: turn,
      initialRemaining: turn.item.remainingMs == null
          ? null
          : Duration(milliseconds: turn.item.remainingMs!),
      onOutcome: (outcome) => _send(
        onAnswer,
        _actionFor(state, isCorrect: outcome == RecallOutcome.revealed),
        // Running out is stored as the reason, never inferred from the action:
        // owning up to a blank produces the same action (BR-131).
        outcomeReason: outcome == RecallOutcome.timedOut
            ? StudyOutcomeReason.timeout
            : null,
      ),
    ),
    StudyMode.fill: () => FillAnswerSectionWidget(
      turn: turn,
      isLocked: state.isSubmitting,
      onGraded: (outcome) => _send(
        onAnswer,
        _actionFor(state, isCorrect: outcome.isCorrect),
        comparisonVersion: outcome.comparisonVersion,
        hasUsedHint: outcome.hasUsedHint,
      ),
    ),
  };

  return builders[mode]?.call();
}

/// Maps a graded outcome to an action, by asking the algorithm (BR-107).
///
/// **Not derived from the order of [StudySessionState.actions].** A first draft
/// took "wrong is the first, right is the last", which happens to be true of
/// `eight_box` and is a coincidence: it would score an `sm2` deck `easy` for
/// every correct answer. The rule already lives on the scheduler, and it returns
/// null for an algorithm with no graded stage precisely so a caller cannot get
/// this wrong quietly.
StudyAction? _actionFor(StudySessionState state, {required bool isCorrect}) =>
    schedulerFor(state.schedulerType)?.binaryAction(isCorrect: isCorrect);

Widget _matchView({
  required StudyTurnModel turn,
  required StudySessionState state,
  required StudyAnswerSink onAnswer,
  required Random random,
}) {
  final board = const MatchModeHandler().buildBoard(state.sessionCards, random);

  // Below two pairs the board is not worth playing (BR-153). The stage is
  // skipped rather than rendered short, and returning nothing lets the session
  // screen say so instead of drawing half a board.
  if (board == null) return const SizedBox.shrink();

  return MatchBoardSectionWidget(
    board: board,
    isLocked: state.isSubmitting,
    onPairAttempt: (_, {required isCorrect}) =>
        _send(onAnswer, _actionFor(state, isCorrect: isCorrect)),
  );
}

Widget _guessView({
  required StudyTurnModel turn,
  required StudySessionState state,
  required StudyAnswerSink onAnswer,
  required Random random,
}) {
  final question = const GuessModeHandler().buildQuestion(
    term: turn.card,
    pool: state.sessionCards,
    random: random,
  );

  // BR-124's blocking case: the stage was allowed to run and this one question
  // still could not be built. Nothing renders, nothing is recorded, and the card
  // is not skipped.
  if (question == null) return const SizedBox.shrink();

  return GuessQuestionSectionWidget(
    question: question,
    isLocked: state.isSubmitting,
    onChosen: (option) => _send(
      onAnswer,
      _actionFor(state, isCorrect: question.isCorrect(option)),
    ),
  );
}

/// Passes an action on, and drops a null.
///
/// Null means the deck's algorithm has no graded stage, so a graded mode is
/// running on a deck that should never have offered it (BR-146). Recording
/// something would be worse than recording nothing: the turn would carry an
/// action the algorithm does not understand.
void _send(
  StudyAnswerSink sink,
  StudyAction? action, {
  StudyOutcomeReason? outcomeReason,
  int? comparisonVersion,
  bool? hasUsedHint,
}) {
  if (action == null) return;

  sink(
    action,
    outcomeReason: outcomeReason,
    comparisonVersion: comparisonVersion,
    hasUsedHint: hasUsedHint,
  );
}
