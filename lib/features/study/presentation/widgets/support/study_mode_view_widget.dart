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
import 'study_swipe_deck_widget.dart';

/// What the session screen tells a mode's widget when an answer arrives.
typedef StudyAnswerSink =
    void Function(
      StudyAction action, {
      String? cardId,
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
///
/// **The shuffles are seeded, not drawn from a live generator** (BR-127). A
/// `Random` handed in from the screen is consumed on every build, so the board
/// was re-dealt and the five options reordered every time anything rebuilt the
/// screen — locking the buttons during a write was enough — and the answer moved
/// under the user's finger. BR-127 also wants both orders stable across a
/// Resume, which a live generator can never be. A seed made of the facts that
/// identify the deal gives the same layout every build and a different one every
/// round.
Widget? studyModeView({
  required StudyMode mode,
  required StudySessionState state,
  required StudyAnswerSink onAnswer,
  required VoidCallback onContinue,

  /// Steps back along `browse`'s trail of cards already seen (BR-155).
  required VoidCallback onLookBack,

  /// Called when the body stops asking and starts telling, so the frame can
  /// swap its hint line for one that describes what is on screen (§8.11).
  VoidCallback? onResolved,
  ValueChanged<Duration>? onRecallTick,
  void Function({required Duration remaining, required bool isRevealed})?
  onRecallSuspend,
}) {
  final turn = state.turn;
  if (turn == null) return null;

  // A graded stage whose algorithm has no right/wrong mapping has nowhere to
  // send an answer (BR-107). It happens when the deck runs an algorithm this
  // build does not recognise — `schedulerFor` returns null, and so does every
  // grade taken on this screen.
  //
  // **Refusing to build is the point.** Building the board anyway is what used
  // to happen, and `_send` then dropped each answer on the floor: the user taps
  // a tile, nothing moves, nothing is written, and there is no way out but
  // force-quitting. Exactly the failure M5.12 fixed one layer down. Null here
  // routes to the blocked state, which says so and offers to leave (BR-82).
  if (mode.isBinaryGraded && _actionFor(state, isCorrect: true) == null) {
    return null;
  }

  final builders = <StudyMode, Widget? Function()>{
    // **`browse` is the one mode that can be walked backwards** (BR-155). Every
    // other mode takes an answer from the card on screen, so putting an
    // already-answered card there would offer to grade what the session has
    // graded — which is why the swipe wraps this entry alone rather than the
    // body as a whole.
    StudyMode.browse: () => StudySwipeDeckWidget(
      cardKey: (state.viewedCard ?? turn.card).id,
      canGoBack: state.canLookBack,
      isLocked: state.isSubmitting,
      onForward: onContinue,
      onBack: onLookBack,
      child: StudyCardFaceSectionWidget(
        turn: turn,
        viewedCard: state.viewedCard,
        // `browse` produces no action at all (BR-111), so it gets no buttons
        // and one way forward.
        actions: const <StudyAction>[],
        onAction: (_) {},
        onContinue: onContinue,
        shouldShowBackImmediately: true,
        isLocked: state.isSubmitting,
      ),
    ),
    StudyMode.selfAssess: () => StudyCardFaceSectionWidget(
      turn: turn,
      actions: state.actions,
      onAction: onAnswer,
      onContinue: onContinue,
      isLocked: state.isSubmitting,
    ),
    // The board belongs to the round, so its seed does not include the card —
    // mixing one in would re-deal between two cards of the same round.
    StudyMode.match: () => _matchView(
      turn: turn,
      state: state,
      onAnswer: onAnswer,
      random: Random(_seedFor(state, turn: turn, isPerCard: false)),
    ),
    // The five options belong to one question, so this one does. BR-127 wants
    // the two permutations independent, and different seeds are what makes them
    // so.
    StudyMode.guess: () => _guessView(
      turn: turn,
      state: state,
      onAnswer: onAnswer,
      random: Random(_seedFor(state, turn: turn, isPerCard: true)),
      onResolved: onResolved,
    ),
    StudyMode.recall: () => RecallTimerSectionWidget(
      turn: turn,
      initialRemaining: turn.item.remainingMs == null
          ? null
          : Duration(milliseconds: turn.item.remainingMs!),
      // The clock is drawn in the frame's top bar (§7.3), so the widget that
      // owns the countdown reports it rather than showing it.
      onRemainingChanged: onRecallTick,
      // And what is left when the app is taken away gets written down (BR-133).
      onSuspended: onRecallSuspend,
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

/// The seed a stage's shuffle is drawn from (BR-127).
///
/// Made of what identifies the deal — the session, the stage, the round, and for
/// a per-question deal the card — so it is the same on every rebuild and after a
/// Resume, and different in the next round.
///
/// **Hashed by hand, because `Object.hash` is not stable across a restart.**
/// Dart randomises `String.hashCode` per isolate, so the same session id seeds a
/// different shuffle in the next process — which is stable on a rebuild and
/// *not* stable on the Resume BR-127 names. A reopened session dealt its match
/// board and its five options in a new arrangement, and the giveaway was a
/// golden render of `guess` that produced a different option order on every run
/// of the same test.
///
/// FNV-1a over the same parts, masked to 31 bits so the value stays a positive
/// int on the web, where an `int` is a double.
int _seedFor(
  StudySessionState state, {
  required StudyTurnModel turn,
  required bool isPerCard,
}) {
  var hash = _fnvOffset;
  void mix(String value) {
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * _fnvPrime) & _seedMask;
    }
  }

  mix(state.session?.id ?? '');
  mix(turn.item.mode.name);
  mix('${turn.item.round}');
  if (isPerCard) mix(turn.cardId);

  return hash;
}

const int _fnvOffset = 0x811c9dc5;
const int _fnvPrime = 0x01000193;
const int _seedMask = 0x7fffffff;

/// The round's cards, resolved against the session's content in the round's own
/// order (BR-156, BR-117).
///
/// The queue knows *which* cards a round holds; only the session read knows what
/// is on them. An id with no card is skipped rather than defaulted — a blank
/// tile is a tile the user would tap.
List<StudyCardModel> _roundCards({
  required StudyTurnModel turn,
  required StudySessionState state,
}) {
  final ids = turn.progress.roundCardIds;
  if (ids.isEmpty) return state.sessionCards;

  final byId = <String, StudyCardModel>{
    for (final card in state.sessionCards) card.id: card,
  };

  return <StudyCardModel>[for (final id in ids) ?byId[id]];
}

Widget? _matchView({
  required StudyTurnModel turn,
  required StudySessionState state,
  required StudyAnswerSink onAnswer,
  required Random random,
}) {
  // **The round's cards, in the round's order** (BR-156). `sessionCards` is
  // every card the session opened with; from round 2 the queue holds only the
  // ones that failed, and dealing from the session laid all of them out under a
  // counter that had already dropped to the failures.
  //
  // Falls back to the session's cards when the round list is empty, which is a
  // hand-built progress in a widget test rather than anything a repository read
  // produces — see `StudyStageProgressModel.roundCardIds`.
  final roundCards = _roundCards(turn: turn, state: state);
  const handler = MatchModeHandler();
  final board = handler.buildBoard(
    roundCards,
    random,
    boardIndex: handler.boardIndexFor(
      done: turn.progress.done,
      cardCount: roundCards.length,
    ),
  );

  // Below two pairs there is no board (BR-153). The stage should never have
  // been laid out — `canRunOn` keeps it out of the queue — so reaching here at
  // all means the card set changed under a session, which BR-102 forbids.
  // Null rather than an empty box: the screen then says the stage cannot run
  // instead of drawing a blank nobody can act on.
  if (board == null) return null;

  return MatchBoardSectionWidget(
    board: board,
    pairedCardIds: turn.progress.completedCardIds.toSet(),
    isLocked: state.isSubmitting,
    // **The term's card, not the queue's** (BR-118). The board lays out the
    // whole round, so the pair a person reaches for is rarely the card the
    // queue happens to be serving — and every turn was being recorded against
    // that one instead. The widget has always reported which term was picked;
    // this is the caller finally using it.
    onPairAttempt: (term, {required isCorrect}) => _send(
      onAnswer,
      _actionFor(state, isCorrect: isCorrect),
      cardId: term.cardId,
    ),
  );
}

Widget? _guessView({
  required StudyTurnModel turn,
  required StudySessionState state,
  required StudyAnswerSink onAnswer,
  required Random random,
  VoidCallback? onResolved,
}) {
  final question = const GuessModeHandler().buildQuestion(
    term: turn.card,
    pool: state.sessionCards,
    random: random,
  );

  // BR-124's blocking case: the stage was allowed to run and this one question
  // still could not be built. Nothing renders, nothing is recorded, and the card
  // is **not** skipped — which means the session cannot move on by itself.
  //
  // Null rather than `SizedBox.shrink()`. An empty box is indistinguishable
  // from a screen that failed to build: the user sees nothing, taps nothing, and
  // the only way out is force-quitting. Null lets the screen say what happened
  // and offer to leave the session (BR-82).
  if (question == null) return null;

  return GuessQuestionSectionWidget(
    onResolved: onResolved,
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
  String? cardId,
  StudyOutcomeReason? outcomeReason,
  int? comparisonVersion,
  bool? hasUsedHint,
}) {
  if (action == null) return;

  sink(
    action,
    cardId: cardId,
    outcomeReason: outcomeReason,
    comparisonVersion: comparisonVersion,
    hasUsedHint: hasUsedHint,
  );
}
