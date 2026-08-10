// The per-mode bodies: which cards a round deals, and the two modes whose body
// has to be *built* rather than handed a turn. A `part` of
// `study_mode_view_widget.dart` so these keep access to the library's private
// helpers — the split exists to satisfy the file-size guard, not to change the
// API, and the resolver above is still the one exhaustive branch (AD-18).
part of 'study_mode_view_widget.dart';

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
  required Random random,
  StudyMatchAttemptSink? onMatchAttempt,
  Future<void> Function()? onMatchBoardComplete,
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
    // **`isLocked` is left at its default of false, and that is a change.** It
    // used to follow `state.isSubmitting`: `match` is the one mode whose next
    // interaction is already on screen, so freezing the whole board for the
    // length of a transaction made every other pair wait for one the user had
    // finished with. The board guards the pair in flight itself.
    // **The term's card, not the queue's** (BR-118). The board lays out the
    // whole round, so the pair a person reaches for is rarely the card the
    // queue happens to be serving — and every turn was being recorded against
    // that one instead. The widget has always reported which term was picked;
    // this is the caller finally using it.
    onPairAttempt: (term, {required isCorrect}) {
      // A null action means the deck runs a scheduler this build has no binary
      // mapping for (BR-107) — the same case the guard above already refuses to
      // build a body at all, so it cannot arise here. A null receipt rather
      // than a `!` so that if it ever does, the pair stays on the board.
      final action = _actionFor(state, isCorrect: isCorrect);
      if (action == null || onMatchAttempt == null) {
        return Future<StudyAnswerCommitModel?>.value();
      }

      return onMatchAttempt(cardId: term.cardId, action: action);
    },
    onBoardComplete: onMatchBoardComplete,
  );
}

Widget? _guessView({
  required StudyTurnModel turn,
  required StudySessionState state,
  required StudyAnswerSink onAnswer,
  required Random random,
  VoidCallback? onResolved,
  StudyFeedbackShownSink? onFeedbackShown,
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
    isLocked: state.isBusy,
    onChosen: (option) => _send(
      onAnswer,
      _actionFor(state, isCorrect: question.isCorrect(option)),
    ),
    onFeedbackShown: onFeedbackShown,
  );
}
