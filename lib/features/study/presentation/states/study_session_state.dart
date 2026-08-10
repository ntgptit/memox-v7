import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../deck/domain/models/scheduler_type_model.dart';

import '../../domain/entities/study_session_entity.dart';
import '../../domain/models/study_action_model.dart';
import '../../domain/models/study_turn_model.dart';

part 'study_session_state.freezed.dart';

/// Which way a `browse` step goes (BR-155).
///
/// An enum rather than a boolean: `browseStep(true)` at a call site says
/// nothing, and the two directions are not each other's negation — forward from
/// the live turn writes, and nothing else does.
///
/// Here rather than in the controller because it is part of the same vocabulary
/// as [StudySessionState.browseLookBack], and because a controller file is for
/// commands, not for the types they take.
enum StudyBrowseStep { forward, back }

/// What a study screen is doing right now.
///
/// **Three task flags, one per operation, and none of them called `isLoading`.**
/// A single shared flag cannot say "the card is on screen and the answer is
/// being written", which is the state the screen spends most of its time in —
/// the content stays visible and only the buttons lock (BR-25). It also cannot
/// tell opening a session apart from fetching the next card, and those two want
/// different chrome: one is a full-screen wait, the other is a beat between
/// cards.
@freezed
abstract class StudySessionState with _$StudySessionState {
  const factory StudySessionState({
    /// Null until the session has opened.
    StudySessionEntity? session,

    /// The turn on screen. Null while loading, and again once the session ends.
    StudyTurnModel? turn,

    /// The deck's algorithm, so a graded mode can ask it what right and wrong
    /// mean (BR-107) instead of guessing from the shape of [actions].
    @Default(SchedulerType.unknown) SchedulerType schedulerType,

    /// The actions this deck's algorithm offers (BR-30).
    ///
    /// Empty until the session opens. The screen renders buttons from this and
    /// never from a list of its own — a hardcoded four is wrong for every
    /// `eight_box` deck.
    @Default(<StudyAction>[]) List<StudyAction> actions,

    /// Every card of the session, for the stages that need the whole set.
    ///
    /// `match` lays out a board and `guess` draws distractors from it (BR-121,
    /// BR-153). Fixed for the session's life (BR-102), so it is read once when
    /// the session opens rather than per turn.
    @Default(<StudyCardModel>[]) List<StudyCardModel> sessionCards,

    /// Opening the session. Nothing is on screen yet.
    @Default(false) bool isOpening,

    /// Fetching the next turn. The previous card has gone and the next has not
    /// arrived — a different thing from opening, and the screen shows a
    /// different amount of chrome for each.
    @Default(false) bool isAdvancing,

    /// Writing an answer. The card **stays** on screen and the buttons lock.
    @Default(false) bool isSubmitting,

    /// The session ran out of queue, or was closed.
    /// True from the moment ✕ or the back gesture is taken until the session has
    /// actually ended (BR-82).
    ///
    /// **A state, not the absence of one.** `leave` used to clear the busy flags
    /// and then await `EndStudySession` — so for the length of that write the
    /// screen was mounted, unlocked and answerable, and the session it would
    /// have been answering was already leaving. Named here so every guard can
    /// ask the same question, and so the screen can keep the card visible while
    /// refusing to act on it.
    @Default(false) bool isLeaving,

    @Default(false) bool isFinished,

    /// What the session came to, once it has ended (BR-79, BR-80).
    ///

    /// Set when something failed. Carries the reason, never a sentence — the
    /// screen maps it to copy.
    Object? error,
  }) = _StudySessionState;

  const StudySessionState._();

  /// Whether the buttons should accept a tap.
  ///
  /// One place, so "locked while writing" cannot be spelled three different ways
  /// across six mode widgets.
  /// Whether an answer may be started at all.
  ///
  /// **`isLeaving` belongs here, and its absence was a race.** Leaving is a trip
  /// to the database like any other, and for its whole length the card was still
  /// on screen with its buttons live — so a tap landing inside it started a turn
  /// on a session already on its way out.
  bool get canAnswer =>
      turn != null &&
      !isSubmitting &&
      !isAdvancing &&
      !isLeaving &&
      !isFinished;

  /// The cards of this round already answered, oldest first.
  ///
  /// Ordered by the queue's `position`, which for a round that serves each card
  /// once is the order the user saw them in — see `completedCardsInRound`.
  List<String> get seenCardIds =>
      turn?.progress.completedCardIds ?? const <String>[];

  /// Whether there is an earlier card to go back to (BR-155).
  /// Whether a write or a fetch is in flight.
  ///
  /// **One name, because a mode has one question to ask.** The card stays on
  /// screen for both — the write so the answer can be read, the fetch so
  /// nothing flashes — and during both, input has to be refused. Asking only
  /// about `isSubmitting` left the whole fetch open, which is a window a second
  /// tap fits inside.
  bool get isBusy => isSubmitting || isAdvancing || isLeaving;

  /// The session is over and nothing is in flight.
  ///
  /// **One definition of the terminal invariant**, because there are three ways
  /// to reach it — the last card, the ✕, and a write that could not be stored —
  /// and each used to spell it out again. A copy that forgets `isLeaving` locks
  /// the screen behind the summary; one that forgets `turn` puts a card there.
  StudySessionState get ended => copyWith(
    isFinished: true,
    isLeaving: false,
    isSubmitting: false,
    isAdvancing: false,
    turn: null,
  );

  /// Whether there is an earlier card to go back to from [lookBack] (BR-155).
  ///
  /// **The offset is a parameter, not a field.** It belongs to
  /// `StudyBrowseTrailController` — it is view state, and the session's own
  /// state is about what the queue is serving. Derivation stays here, next to
  /// the turn and the card set it derives from.
  bool canLookBackFrom(int lookBack) => lookBack < seenCardIds.length;

  /// Whether the card on screen is one already seen rather than the live turn.
  ///
  /// **A trail needs a turn to be counted back from.** Leaving the session
  /// clears [turn] and leaves the offset where it was, and without this the
  /// state would claim to be showing an earlier card while holding no card at
  /// all — which is the sort of thing that is invisible until the day something
  /// renders from it.
  bool isLookingBackAt(int lookBack) => lookBack > 0 && turn != null;

  /// The card to draw: the live turn's, or an earlier one while looking back.
  ///
  /// **Falls back to the live card rather than to nothing.** A trail naming a
  /// card that is not in [sessionCards] means the two reads disagree, and an
  /// empty card face would be a screen that has silently lost its content. The
  /// live card is wrong by one position; a blank card is wrong about what the
  /// app is for.
  StudyCardModel? viewedCardAt(int lookBack) {
    final live = turn?.card;
    if (!isLookingBackAt(lookBack)) return live;

    final seen = seenCardIds;
    final index = seen.length - lookBack;
    if (index < 0 || index >= seen.length) return live;

    final id = seen[index];

    for (final card in sessionCards) {
      if (card.id == id) return card;
    }

    return live;
  }
}
