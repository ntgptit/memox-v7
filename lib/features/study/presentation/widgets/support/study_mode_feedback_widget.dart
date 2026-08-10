import '../../../domain/models/study_mode.dart';

/// How long a mode's answer stays readable before the next turn replaces it.
///
/// **A hold is not an animation, and that is why none of these is an
/// `AppDurations` token.** That scale is for motion — its longest rung is 320ms
/// because a transition longer than that reads as lag. These are *reading*
/// budgets: how long a person needs to take in what the screen has just said,
/// and the answer depends entirely on how much it said. A ticked pair is a
/// confirmation of something already known; a fill answered wrongly is a
/// spelling to compare against your own, which is two readings and a diff.
///
/// **Wrong outlasts right in every mode.** A correct answer needs to be
/// noticed; an incorrect one needs to be read, found among the options, and
/// understood. The gap is widest where the correction carries the most text.
///
/// The colour transition underneath still runs on `AppDurations.normal`. These
/// begin where that ends: they are how long the *resolved* state exists.
final class StudyModeFeedback {
  const StudyModeFeedback({required this.correct, required this.wrong});

  /// Nothing to read, so nothing to wait for.
  const StudyModeFeedback.none()
    : correct = Duration.zero,
      wrong = Duration.zero;

  final Duration correct;
  final Duration wrong;

  Duration of({required bool isCorrect}) => isCorrect ? correct : wrong;
}

/// The reading budgets, named one at a time so each is a decision with a reason
/// rather than a number inside a table.
abstract final class AppStudyFeedback {
  /// Right is one row confirmed, and the eye is already on it.
  static const Duration guessCorrect = Duration(milliseconds: 800);

  /// **Wrong is a search, and 1200ms was timing the wrong task.** The learner
  /// has to find the row they picked, then find the right answer somewhere among
  /// five meanings that each run to three or four lines, then read it. That is
  /// not a glance.
  static const Duration guessWrong = Duration(milliseconds: 1800);

  /// Right is a tick beside what you typed.
  static const Duration fillCorrect = Duration(milliseconds: 800);

  /// Wrong is the correct spelling to compare your own against, which is a diff
  /// done by eye.
  static const Duration fillWrong = Duration(milliseconds: 2200);
}

/// The reading budget for each mode (§8.12).
///
/// Exhaustive on [StudyMode] by construction, so a mode added later cannot ship
/// without someone deciding how long its answer stays up — which is exactly how
/// `guess`, `recall` and `fill` came to have none at all: they inherited the
/// shared flow, and the shared flow fetched the next card the moment the write
/// returned.
StudyModeFeedback studyModeFeedback(StudyMode mode) => switch (mode) {
  // The board keeps its own beats: a pair is held by the tile
  // (`AppMatchTile.successFlash` / `wrongHold`) because only the board knows
  // whether the pair that just landed was the last one. What the session waits
  // for is the swap after that last pair, which the board asks for itself.
  StudyMode.match => const StudyModeFeedback.none(),
  StudyMode.guess => const StudyModeFeedback(
    correct: AppStudyFeedback.guessCorrect,
    wrong: AppStudyFeedback.guessWrong,
  ),
  // **`recall` times its own reading, and neither of its endings is a budget.**
  // An assessment is given *after* the learner has read the back — holding the
  // screen afterwards would pause them on something they are done with. A
  // timeout is the opposite: the card was lost to a clock, so the reading has
  // no length anyone else can pick, and it ends at a *Next* the learner
  // presses. A fixed 1800/2200ms tried to answer both and was wrong twice.
  StudyMode.recall => const StudyModeFeedback.none(),
  StudyMode.fill => const StudyModeFeedback(
    correct: AppStudyFeedback.fillCorrect,
    wrong: AppStudyFeedback.fillWrong,
  ),

  // `self_assess` is the user's own verdict — they already know it, and there
  // is nothing on screen they have not just read. `browse` grades no card at
  // all (BR-111), so its trail moves as fast as a thumb.
  StudyMode.selfAssess => const StudyModeFeedback.none(),
  StudyMode.browse => const StudyModeFeedback.none(),
  StudyMode.unknown => const StudyModeFeedback.none(),
};
