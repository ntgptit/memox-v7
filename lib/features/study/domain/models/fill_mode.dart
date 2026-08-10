import 'study_lapse_policy_model.dart';
import 'study_entry_summary_model.dart';
import 'study_mode.dart';
import 'study_turn_model.dart';

/// Which comparison policy graded a turn (BR-135).
///
/// **Stored on every `fill` answer, and never applied retroactively.** Changing
/// how answers are compared bumps this number; old rows keep the version they
/// were graded under, so a history row still means what it meant when it was
/// written.
///
/// **2 since the direction was fixed**, and that is the case this number exists
/// for. Version 1 compared the answer with `back_folded`; version 2 compares it
/// with `front_folded`. Leaving it at 1 would have made one number mean two
/// different policies — every row already in `study_answers` says "graded
/// against the back" and every new one would say "graded against the front"
/// under the same label, which is precisely the ambiguity BR-135 forbids and
/// which nothing downstream could unpick afterwards.
///
/// The folding itself — trim, then Unicode-aware lower case — is unchanged; it
/// is *which string is folded against* that moved, and a policy version covers
/// the comparison as a whole.
const int kFillComparisonVersion = 2;

/// What one typed answer produced.
///
/// **The text the user typed is not in here, on purpose** (BR-138, BR-51).
/// Only the outcome, the policy version and whether a hint was used ever leave
/// this class — card content is private data, and a wrong answer is the most
/// private thing in the app.
final class FillOutcome {
  const FillOutcome({
    required this.isCorrect,
    required this.comparisonVersion,
    required this.hasUsedHint,
  });

  final bool isCorrect;
  final int comparisonVersion;

  /// Recorded, and deliberately without effect on the action or the schedule
  /// (BR-136). Whether a hint makes an answer worth less is a judgement nobody
  /// has made; recording it keeps the option open without pretending.
  final bool hasUsedHint;
}

/// Type the answer.
///
/// `fill` takes only cards carrying an `example`, and that field is optional
/// (BR-114) — which is why this is the mode whose count differs from every
/// other, and why BR-154 forbids one shared number on the chooser.
final class FillModeHandler extends StudyModeHandler {
  const FillModeHandler();

  @override
  StudyLapsePolicy get lapsePolicy =>
      StudyLapsePolicy.completeAndEnrollNextRound;

  @override
  int capacityFrom(StudyEntrySummaryModel summary) => summary.fillableCount;

  /// Only a card carrying an example can be asked about (BR-114).
  ///
  /// **This is the rule that nearly froze most of a deck.** `example` is
  /// optional, and an earlier reading had a card finish the chain only after
  /// reaching the *last stage in the sequence* — which is this one. Every card
  /// without an example would have waited there for good.
  @override
  bool canTake(StudyCardModel card) => (card.example ?? '').trim().isNotEmpty;

  /// The comparison policy of BR-134: trim both ends, then lower case in a
  /// Unicode-aware way.
  ///
  /// **Diacritics survive.** `cong` is not `công`, and folding them together
  /// would mark a wrong answer right in the one language this app was built for.
  /// Dart's `toLowerCase` is Unicode-aware; SQLite's `lower()` is ASCII-only,
  /// which is why the folded column exists at all.
  ///
  /// **Restated here rather than borrowed from the Card feature.** The policy is
  /// versioned by [kFillComparisonVersion], so it has to change only when
  /// somebody decides to change it — pointing at a helper another feature owns
  /// would let an edit over there silently re-grade history over here.
  static String fold(String value) => value.trim().toLowerCase();

  /// Grades one answer, or returns null when there is nothing to grade.
  ///
  /// **Against the folded *front*, and the direction is the mode** (BR-134).
  /// `fill` puts the card's back — the English/Vietnamese meaning — on the
  /// prompt and asks for the Korean term, so the string an answer is measured
  /// against is [StudyCardModel.frontFolded]. It graded against the back for as
  /// long as the prompt was the example sentence: a learner typing the Korean
  /// word was marked wrong, and one echoing the gloss back was marked right.
  ///
  /// **Null for an empty answer** (BR-137). Not "wrong": a blank field is
  /// somebody tapping submit by accident, and recording it as a failure would
  /// bury a card the user never actually got wrong. It also must not advance the
  /// checkpoint, which is what returning null lets the caller do.
  FillOutcome? grade({
    required String input,
    required String frontFolded,
    required bool hasUsedHint,
  }) {
    final folded = fold(input);
    if (folded.isEmpty) return null;

    return FillOutcome(
      isCorrect: folded == frontFolded,
      comparisonVersion: kFillComparisonVersion,
      hasUsedHint: hasUsedHint,
    );
  }
}
