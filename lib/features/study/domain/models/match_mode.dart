import 'dart:math';

import 'study_entry_summary_model.dart';
import 'study_mode.dart';
import 'study_turn_model.dart';

/// The smallest board worth playing (BR-153).
///
/// One pair makes the answer self-evident: whatever is on the left goes with
/// whatever is on the right, and the user learns nothing.
const int kMinMatchPairs = 2;

/// One side of the board, carrying the card it belongs to.
///
/// **The card id travels with the text, and that is the point** (BR-125). A
/// board matched by comparing displayed strings breaks the moment two cards read
/// alike, and grades the wrong card when it does.
final class MatchTile {
  const MatchTile({
    required this.cardId,
    required this.text,
    required this.isTerm,
  });

  final String cardId;
  final String text;

  /// True for the front. **The turn belongs to the term's card** (BR-118):
  /// picking the wrong meaning must not mark the card that owns that meaning as
  /// failed — it was not the card being asked about.
  final bool isTerm;
}

/// A board: terms down one side, meanings down the other, shuffled apart.
final class MatchBoard {
  const MatchBoard({required this.terms, required this.meanings});

  final List<MatchTile> terms;
  final List<MatchTile> meanings;

  /// Whether [term] and [meaning] belong to the same card.
  bool isPair(MatchTile term, MatchTile meaning) =>
      term.cardId == meaning.cardId;
}

/// Pair the term with its meaning.
final class MatchModeHandler extends StudyModeHandler {
  const MatchModeHandler();

  @override
  int capacityFrom(StudyEntrySummaryModel summary) =>
      summary.dueCount >= kMinMatchPairs ? summary.dueCount : 0;

  /// Lays out a board, or null when there are too few pairs (BR-153).
  ///
  /// **Two independent shuffles** (BR-127): if one order drove the other, the
  /// board would read straight across and the answer would be the row number.
  /// Below two pairs there is no board to play (BR-153).
  @override
  bool canRunOn(List<StudyCardModel> cards) => cards.length >= kMinMatchPairs;

  MatchBoard? buildBoard(List<StudyCardModel> cards, Random random) {
    if (cards.length < kMinMatchPairs) return null;

    final terms = <MatchTile>[
      for (final card in cards)
        MatchTile(cardId: card.id, text: card.front, isTerm: true),
    ]..shuffle(random);
    final meanings = <MatchTile>[
      for (final card in cards)
        MatchTile(cardId: card.id, text: card.back, isTerm: false),
    ]..shuffle(random);

    return MatchBoard(terms: terms, meanings: meanings);
  }
}
