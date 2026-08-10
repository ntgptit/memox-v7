import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../../domain/models/guess_mode.dart';
import '../../../domain/models/match_mode.dart';
import '../../../domain/models/study_action_model.dart';
import '../../../domain/models/study_answer_commit_model.dart';
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

part 'study_mode_bodies_widget.dart';

/// What the session screen tells a mode's widget when an answer arrives.
/// One `match` pair, written on its own and awaited by the board.
///
/// Writes one answer and hands back **what the transaction did** — null when
/// there was no transaction.
///
/// **A `Future<void>` here was a bug with two faces.** A future completing says
/// only that the call returned; it does not say a row was written. `match` read
/// it as success and cleared the pair, so a refused write emptied a slot the
/// session does not remember; and a second tap arriving during the first write
/// was refused by the controller with a quiet `null` that the board also read as
/// success. BR-157 is the rule this type now carries: nothing graded is drawn
/// before the write that holds it has committed.
typedef StudyAnswerSink =
    Future<StudyAnswerCommitModel?> Function(
      StudyAction action, {
      String? cardId,
      StudyOutcomeReason? outcomeReason,
      int? comparisonVersion,
      bool? hasUsedHint,
    });

/// The same write, named for `match`'s use of it: a pair at a time, no fetch.
///
/// Five pairs on a board cost five writes and one read instead of five of each
/// (BR-25 keeps the writes).
typedef StudyMatchAttemptSink =
    Future<StudyAnswerCommitModel?> Function({
      required String cardId,
      required StudyAction action,
    });

/// Called by a mode once its graded state is **on screen**, and completes when
/// the session has moved on.
///
/// **The reading budget starts here, not at the tap and not at the write.** A
/// hold measured from the tap spends itself on the transaction; one measured
/// from the write starts before anything is drawn. The mode is the only thing
/// that knows when its verdict actually became visible, so it is the mode that
/// says so — and the holding and the fetching stay in one place rather than
/// being copied into five widgets.
typedef StudyFeedbackShownSink =
    Future<void> Function({required bool isCorrect});

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

  /// How many cards back the trail is looking, owned by
  /// `StudyBrowseTrailController`. Zero is the card the queue is serving.
  int browseLookBack = 0,

  /// Called when the body stops asking and starts telling, so the frame can
  /// swap its hint line for one that describes what is on screen (§8.11).
  VoidCallback? onResolved,

  /// Holds the mode's verdict for its reading budget, then advances (BR-158).
  StudyFeedbackShownSink? onFeedbackShown,

  /// Writes one `match` pair and resolves when the database has it.
  StudyMatchAttemptSink? onMatchAttempt,

  /// Fetches the next board, once every pair on this one has landed.
  Future<void> Function()? onMatchBoardComplete,
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

  // **A `switch`, and this is the presentation half of AD-18's one dispatch.**
  // It was a `Map<StudyMode, Widget? Function()>` on the reading that AD-18
  // allows exactly one exhaustive branch — but what AD-18 forbids is a second
  // branch in the *controller or the use case*, the layers that decide what a
  // turn does. This one decides what a turn looks like, which is the one
  // question `domain/` may not answer at all: it may not import Flutter.
  //
  // The map cost what a map always costs here — a mode left out of it built
  // nothing and said nothing, at runtime, on the screen. A missing arm below is
  // a compile error, which is the whole reason the domain resolver is a switch
  // too.
  final builder = switch (mode) {
    // **`browse` is the one mode that can be walked backwards** (BR-155). Every
    // other mode takes an answer from the card on screen, so putting an
    // already-answered card there would offer to grade what the session has
    // graded — which is why the swipe wraps this entry alone rather than the
    // body as a whole.
    StudyMode.browse => () => StudySwipeDeckWidget(
      cardKey: (state.viewedCardAt(browseLookBack) ?? turn.card).id,
      canGoBack: state.canLookBackFrom(browseLookBack),
      // **`isAdvancing` too, not just `isSubmitting`.** Stepping forward from
      // the live turn writes the browse progress and *then* pulls the next
      // turn; only the write was covered, so the whole fetch was a window in
      // which a second swipe counted.
      isLocked: state.isBusy,
      onForward: onContinue,
      onBack: onLookBack,
      child: StudyCardFaceSectionWidget(
        turn: turn,
        viewedCard: state.viewedCardAt(browseLookBack),
        // `browse` produces no action at all (BR-111), so it gets no buttons
        // and one way forward — and therefore nothing to write, which is what
        // the null receipt says.
        actions: const <StudyAction>[],
        onAction: (_) async => null,
        onContinue: onContinue,
        shouldShowBackImmediately: true,
        // The front is the term and the back is its meaning (BR-08), so the
        // front leads and the back explains.
        emphasis: StudyFaceEmphasis.backSupportingFront,
        isLocked: state.isBusy,
      ),
    ),
    StudyMode.selfAssess => () => StudyCardFaceSectionWidget(
      turn: turn,
      actions: state.actions,
      onAction: onAnswer.call,
      onFeedbackShown: onFeedbackShown,
      onContinue: onContinue,
      isLocked: state.isBusy,
    ),
    // The board belongs to the round, so its seed does not include the card —
    // mixing one in would re-deal between two cards of the same round.
    StudyMode.match => () => _matchView(
      turn: turn,
      state: state,
      random: Random(_seedFor(state, turn: turn, isPerCard: false)),
      onMatchAttempt: onMatchAttempt,
      onMatchBoardComplete: onMatchBoardComplete,
    ),
    // The five options belong to one question, so this one does. BR-127 wants
    // the two permutations independent, and different seeds are what makes them
    // so.
    StudyMode.guess => () => _guessView(
      turn: turn,
      state: state,
      onAnswer: onAnswer,
      random: Random(_seedFor(state, turn: turn, isPerCard: true)),
      onResolved: onResolved,
      onFeedbackShown: onFeedbackShown,
    ),
    StudyMode.recall => () => RecallTimerSectionWidget(
      turn: turn,
      isLocked: state.isBusy,
      onResolved: onResolved,
      initialRemaining: turn.item.remainingMs == null
          ? null
          : Duration(milliseconds: turn.item.remainingMs!),
      // The clock is drawn in the frame's top bar (§7.3), so the widget that
      // owns the countdown reports it rather than showing it.
      onRemainingChanged: onRecallTick,
      // And what is left when the app is taken away gets written down (BR-133).
      onSuspended: onRecallSuspend,
      // **Three outcomes, and the widget no longer sends one for looking.**
      // Reveal used to arrive here as `RecallOutcome.revealed` and was mapped to
      // *correct*, so giving up early promoted the card (BR-159). What reaches
      // this line now is a verdict the learner gave, or a clock that ran out.
      onOutcome: (outcome) => _send(
        onAnswer,
        _actionFor(state, isCorrect: outcome.isCorrect),
        // Running out is stored as the reason, never inferred from the action:
        // owning up to a blank produces the same action (BR-131).
        outcomeReason: outcome.reason,
      ),
      onFeedbackShown: onFeedbackShown,
    ),
    StudyMode.fill => () => FillAnswerSectionWidget(
      turn: turn,
      isLocked: state.isBusy,
      onGraded: (outcome) => _send(
        onAnswer,
        _actionFor(state, isCorrect: outcome.isCorrect),
        comparisonVersion: outcome.comparisonVersion,
        hasUsedHint: outcome.hasUsedHint,
      ),
      onFeedbackShown: onFeedbackShown,
    ),
    // A mode this build does not recognise cannot be run, only read (BR-107).
    StudyMode.unknown => null,
  };

  return builder?.call();
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

/// Passes an action on, and drops a null.
///
/// A null action means the deck runs a scheduler with no binary mapping
/// (BR-107) — refused above, so unreachable here. It resolves to a null receipt
/// rather than a crash, which is the same answer as a refused write: nothing was
/// recorded, so nothing is drawn.
///
/// Null means the deck's algorithm has no graded stage, so a graded mode is
/// running on a deck that should never have offered it (BR-146). Recording
/// something would be worse than recording nothing: the turn would carry an
/// action the algorithm does not understand.
Future<StudyAnswerCommitModel?> _send(
  StudyAnswerSink sink,
  StudyAction? action, {
  StudyOutcomeReason? outcomeReason,
  int? comparisonVersion,
  bool? hasUsedHint,
}) {
  if (action == null) return Future<StudyAnswerCommitModel?>.value();

  return sink(
    action,
    outcomeReason: outcomeReason,
    comparisonVersion: comparisonVersion,
    hasUsedHint: hasUsedHint,
  );
}
