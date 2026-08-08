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

extension ItRobotStudyDriving on ItRobot {
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
            'visible text was $visibleText',
      );
    }

    fail('the session was still running after $_kMaxStudyTurns turns');
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

    return true;
  }

  /// `recall`: revealing is the outcome (BR-129), so one tap is the whole turn.
  Future<bool> _answerRecall() async {
    if (find.byType(RecallTimerSectionWidget).evaluate().isEmpty) return false;

    await tapText(ItText.studyRevealAnswer);

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

    return true;
  }

  /// `browse` moves on; `self_assess` takes the action straight from the user.
  Future<bool> _answerCardFace() async {
    if (find.byType(StudyCardFaceSectionWidget).evaluate().isEmpty) {
      return false;
    }

    if (find.text(ItText.studyContinue).evaluate().isNotEmpty) {
      await tapText(ItText.studyContinue);

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
