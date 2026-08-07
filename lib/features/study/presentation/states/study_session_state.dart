import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/study_session_entity.dart';
import '../../domain/models/study_action_model.dart';
import '../../domain/models/study_turn_model.dart';

part 'study_session_state.freezed.dart';

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
    @Default(false) bool isFinished,

    /// Set when something failed. Carries the reason, never a sentence — the
    /// screen maps it to copy.
    Object? error,
  }) = _StudySessionState;

  const StudySessionState._();

  /// Whether the buttons should accept a tap.
  ///
  /// One place, so "locked while writing" cannot be spelled three different ways
  /// across six mode widgets.
  bool get canAnswer => turn != null && !isSubmitting && !isFinished;
}
