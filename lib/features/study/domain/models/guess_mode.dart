import 'dart:math';

import 'study_entry_summary_model.dart';
import 'study_mode.dart';
import 'study_turn_model.dart';

/// How many options a question shows (BR-121).
const int kGuessOptionCount = 5;

/// One option, identified by the card it came from.
///
/// Chosen by identity, never by the string on screen (BR-125): two cards can
/// display the same way, and comparing text would grade the wrong one.
final class GuessOption {
  const GuessOption({required this.cardId, required this.text});

  final String cardId;
  final String text;
}

/// One question: a term, five meanings, one of them right.
final class GuessQuestion {
  const GuessQuestion({required this.term, required this.options});

  final StudyCardModel term;
  final List<GuessOption> options;

  bool isCorrect(GuessOption option) => option.cardId == term.id;
}

/// Pick the meaning out of five.
final class GuessModeHandler implements StudyModeHandler {
  const GuessModeHandler();

  @override
  int capacityFrom(StudyEntrySummaryModel summary) =>
      summary.distinctMeanings >= kGuessOptionCount ? summary.dueCount : 0;

  /// Builds one question, or null when five distinct meanings cannot be found.
  ///
  /// **Distinctness is measured on `back_folded`, not on the displayed string**
  /// (BR-123). Two cards that merely *look* different — different case, stray
  /// spacing — are the same meaning, and an option set holding both has two
  /// right answers.
  ///
  /// Null here is BR-124's blocking case: the stage was allowed to run, and this
  /// one question still could not be assembled. The caller must not render, not
  /// record a turn, and not skip the card.
  GuessQuestion? buildQuestion({
    required StudyCardModel term,
    required List<StudyCardModel> pool,
    required Random random,
  }) {
    final seen = <String>{term.backFolded};
    final distractors = <GuessOption>[];

    for (final card in <StudyCardModel>[...pool]..shuffle(random)) {
      if (distractors.length == kGuessOptionCount - 1) break;
      if (card.id == term.id) continue;
      if (!seen.add(card.backFolded)) continue;

      distractors.add(GuessOption(cardId: card.id, text: card.back));
    }

    if (distractors.length < kGuessOptionCount - 1) return null;

    // The correct option appears exactly once, and its position is shuffled
    // independently of the card order (BR-121, BR-127).
    final options = <GuessOption>[
      GuessOption(cardId: term.id, text: term.back),
      ...distractors,
    ]..shuffle(random);

    return GuessQuestion(term: term, options: options);
  }
}
