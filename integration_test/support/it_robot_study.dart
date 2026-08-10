// The study-driving half of the robot: answering one turn of whichever stage
// is on screen, and walking a session to its end. A `part` of it_robot.dart so
// these extension members keep access to the robot's private tester and
// harness — the split exists to satisfy the file-size guard, not to change the
// API: tests still call everything as `robot.<method>`.
part of 'it_robot.dart';

/// How many turns a run through one session may take before the robot gives up.
///
/// **A ceiling, not an expectation.** Five cards over four stages is twenty
/// turns; a wrong answer would add a round. The number exists so a session that
/// stops advancing fails as "stuck after N turns" instead of hanging until the
/// suite times out — which is the failure mode that once cost 34 minutes.
const int _kMaxStudyTurns = 60;

/// How far a swipe travels. Comfortably past `kStudySwipeThreshold`, so a change
/// to the threshold shows up as a failing card change rather than as a robot
/// that silently stops advancing.
const double _kSwipeTravel = 160;

extension ItRobotStudyDriving on ItRobot {
  /// Waits out the window in which the answer just given is on screen.
  ///
  /// **A person cannot answer the next card until this has passed, and neither
  /// can the robot.** Every graded mode holds its verdict for a fixed beat
  /// before the session swaps in the next turn (BR-158, §8.12) — and the beat is
  /// a `Future.delayed`, which schedules no frames, so `pumpAndSettle` returns
  /// straight through it. Without this the robot answered a card that was still
  /// showing the previous card's result, burned turns doing it, and ran out at
  /// the turn cap.
  ///
  /// The wrong-answer budget, because it is the longer of the two and the robot
  /// does not know which way the grade went until the screen changes.
  Future<void> _holdFeedback(StudyMode mode) async {
    final feedback = studyModeFeedback(mode);
    final longest = feedback.wrong > feedback.correct
        ? feedback.wrong
        : feedback.correct;
    if (longest == Duration.zero) return;

    await _tester.pump(longest + const Duration(milliseconds: 200));
    await _harness.settle();
  }

  /// Answers the turn on screen correctly, whichever stage it belongs to.
  ///
  /// **It reads the screen rather than the rules.** The right pair, the right
  /// option and the right spelling all come out of the widget the app just
  /// built — which is what a person does — so this cannot drift from the
  /// scheduler the way a robot holding its own copy of the answer would.
  ///
  /// Returns false when nothing answerable is on screen, which is how
  /// [studyUntilFinished] tells "the session ended" from "the session is stuck".
  Future<bool> answerStudyTurn() async {
    if (await _answerMatch()) return true;
    if (await _answerGuess()) return true;
    if (await _answerRecall()) return true;
    if (await _answerFill()) return true;

    return _answerCardFace();
  }

  /// Runs the session until the summary appears, or fails saying where it stuck.
  Future<int> studyUntilFinished() async {
    for (var turn = 0; turn < _kMaxStudyTurns; turn++) {
      if (find.text(ItText.studyBackToDeck).evaluate().isNotEmpty) return turn;
      final answered = await answerStudyTurn();
      expect(
        answered,
        isTrue,
        reason:
            'turn $turn had nothing to answer and no summary; '
            'the stage was ${_stageOnScreen()} and the visible text was '
            '$visibleText',
      );
    }

    fail('the session was still running after $_kMaxStudyTurns turns');
  }

  /// Which mode's body is on screen, for a failure message that names it.
  ///
  /// A blocked screen says only that the stage could not build content; which
  /// stage that was is the first thing anybody reading the failure asks.
  String _stageOnScreen() {
    if (find.byType(MatchBoardSectionWidget).evaluate().isNotEmpty) {
      return 'match';
    }
    if (find.byType(GuessQuestionSectionWidget).evaluate().isNotEmpty) {
      return 'guess';
    }
    if (find.byType(RecallTimerSectionWidget).evaluate().isNotEmpty) {
      return 'recall';
    }
    if (find.byType(FillAnswerSectionWidget).evaluate().isNotEmpty) {
      return 'fill';
    }
    if (find.byType(StudyCardFaceSectionWidget).evaluate().isNotEmpty) {
      return 'browse or self_assess';
    }

    return 'none — no mode body was built';
  }

  /// `match`: the board says which meaning belongs to the selected term.
  Future<bool> _answerMatch() async {
    final board = find.byType(MatchBoardSectionWidget);
    if (board.evaluate().isEmpty) return false;

    // **The first term still open, not the first term.** A paired tile stays on
    // the board (§4) and stops being a target, so a robot that always reached
    // for row one tapped a finished tile from the second pair onwards — and the
    // session never advanced, which is how this read as "stuck after 60 turns".
    final open = _tester
        .widgetList<MatchTileWidget>(find.byType(MatchTileWidget))
        .where((tile) => tile.state == MatchTileState.idle)
        .map((tile) => tile.text)
        .toSet();

    // **A board with nothing open is a board that has been finished**, not a
    // board that is stuck. Its last pair is cleared and the session is fetching
    // the next one underneath it — the board stays mounted throughout (BR-158),
    // which is the whole point of the change that made this case reachable.
    // Waiting is what a person does; `firstWhere` threw `Bad state: No element`
    // and named nothing.
    if (open.isEmpty) {
      await _harness.settle();

      return true;
    }

    final widget = _tester.widget<MatchBoardSectionWidget>(board);
    final term = widget.board.terms.firstWhere(
      (tile) => open.contains(tile.text),
    );
    final meaning = widget.board.meanings.firstWhere(
      (tile) => tile.cardId == term.cardId,
    );

    await tapText(term.text);
    await tapText(meaning.text);

    return true;
  }

  /// `guess`: the question knows which of its five options is right (BR-121).
  Future<bool> _answerGuess() async {
    final question = find.byType(GuessQuestionSectionWidget);
    if (question.evaluate().isEmpty) return false;

    final widget = _tester.widget<GuessQuestionSectionWidget>(question);
    final correct = widget.question.options.firstWhere(
      widget.question.isCorrect,
    );

    await tapText(correct.text);
    await _holdFeedback(StudyMode.guess);

    return true;
  }

  /// `recall`: reveal, then say which it was — **two taps, one answer**.
  ///
  /// **Revealing used to be the whole turn, and that was the bug** (BR-159).
  /// Pressing *Show answer* wrote the correct action and pulled the next card,
  /// so this robot could tap once and call the turn answered. It now opens a
  /// question instead, and the robot answers it the way a learner who knew the
  /// card would.
  ///
  /// The other ending needs no reveal and takes no verdict: a turn the clock
  /// took has already written its wrong answer and is waiting on *Next*
  /// (BR-130). Both endings are checked by what is on screen rather than by
  /// timing, because on a slow device the clock can win a turn this robot meant
  /// to answer.
  Future<bool> _answerRecall() async {
    if (find.byType(RecallTimerSectionWidget).evaluate().isEmpty) return false;

    if (find.text(ItText.studyRevealAnswer).evaluate().isNotEmpty) {
      await tapText(ItText.studyRevealAnswer);
    }

    if (find.text(ItText.studyActionRemembered).evaluate().isNotEmpty) {
      await tapText(ItText.studyActionRemembered);
      await _holdFeedback(StudyMode.recall);

      return true;
    }

    // Timed out. The answer is in; what is left is reading the back for as long
    // as the learner wants, which for a robot is no time at all.
    if (find.text(ItText.studyContinue).evaluate().isNotEmpty) {
      await tapText(ItText.studyContinue);

      return true;
    }

    // A write is still open, or the next turn has not arrived. Waiting is the
    // honest move; if the queue never moves, [studyUntilFinished] still ends at
    // its turn cap and says where it stuck.
    await _harness.settle();

    return true;
  }

  /// `fill`: type the card's own back, which is what a learner who knew it would
  /// type. Graded against `back_folded` with diacritics intact (BR-134).
  Future<bool> _answerFill() async {
    final field = find.byType(FillAnswerSectionWidget);
    if (field.evaluate().isEmpty) return false;

    final widget = _tester.widget<FillAnswerSectionWidget>(field);
    await _tester.enterText(
      find.descendant(of: field, matching: find.byType(TextField)),
      widget.turn.card.back,
    );
    await _harness.settle();
    await tapText(ItText.studyFillSubmit);
    await _holdFeedback(StudyMode.fill);

    return true;
  }

  /// `browse` is swiped past; `self_assess` takes the action from the user.
  Future<bool> _answerCardFace() async {
    if (find.byType(StudyCardFaceSectionWidget).evaluate().isEmpty) {
      return false;
    }

    // **`browse` has no control at all** (BR-111, BR-155). It used to have a
    // Next button and this robot tapped it; the button was removed because
    // moving between cards is the swipe, and the band of screen it took belongs
    // to the card, which is the entire content of this mode.
    final deck = find.byType(StudySwipeDeckWidget);
    if (deck.evaluate().isNotEmpty) {
      await _tester.drag(deck, const Offset(-_kSwipeTravel, 0));
      await _harness.settle();

      return true;
    }

    // `self_assess` shows the front first and the actions only after a flip
    // (BR-112).
    if (find.text(ItText.studyRevealAnswer).evaluate().isNotEmpty) {
      await tapText(ItText.studyRevealAnswer);
    }
    await tapText(ItText.studyActionRemembered);

    return true;
  }
}
