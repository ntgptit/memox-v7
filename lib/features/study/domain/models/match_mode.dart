import 'study_lapse_policy_model.dart';
import 'dart:math';

import 'study_entry_summary_model.dart';
import 'study_mode.dart';
import 'study_turn_model.dart';

/// The smallest board worth playing (BR-153).
///
/// One pair makes the answer self-evident: whatever is on the left goes with
/// whatever is on the right, and the user learns nothing.
const int kMinMatchPairs = 2;

/// How many pairs a single board shows (BR-156).
///
/// **A round is dealt into boards; it is not one board.** Twenty due cards laid
/// out at once is forty tiles, and past about five pairs the board stops being a
/// thing you scan and becomes a thing you search — every tap costs a re-read of
/// everything still on it. Five keeps the whole board in view on the narrowest
/// screen the project supports and keeps a tile tall enough to hit.
///
/// The last board of a round takes the remainder, and the remainder may be one
/// pair. That is the one place [kMinMatchPairs] does not apply: BR-153 keeps a
/// *stage* off the chooser when the whole round is a single obvious pair, which
/// is a different thing from the tail of a round the user has already worked
/// through — see BR-156.
const int kMatchPairsPerBoard = 5;

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
  StudyLapsePolicy get lapsePolicy => StudyLapsePolicy.retainAndEnrollNextRound;

  @override
  int capacityFrom(StudyEntrySummaryModel summary) =>
      summary.dueCount >= kMinMatchPairs ? summary.dueCount : 0;

  /// Below two pairs there is no board to play (BR-153).
  @override
  bool canRunOn(List<StudyCardModel> cards) => cards.length >= kMinMatchPairs;

  /// How many boards a round of [cardCount] cards is dealt into (BR-156).
  int boardCount(int cardCount) => cardCount <= 0
      ? 0
      : (cardCount + kMatchPairsPerBoard - 1) ~/ kMatchPairsPerBoard;

  /// Which board a round is on, given how many of its cards are answered.
  ///
  /// A board is finished when every pair on it has been taken, so the count of
  /// answered cards *is* the position in the deal. Clamped to the last board:
  /// the final answer of a round arrives before the stage advances, and for that
  /// one frame `done` equals the round size.
  int boardIndexFor({required int done, required int cardCount}) {
    final last = boardCount(cardCount) - 1;
    if (last <= 0) return 0;

    final index = done ~/ kMatchPairsPerBoard;

    return index > last ? last : index;
  }

  /// Lays out **one** board of a round, or null when the round is too small to
  /// play at all (BR-153).
  ///
  /// [cards] is the round's cards in the round's own order (BR-117) — the caller
  /// takes them from `StudyStageProgressModel.roundCardIds`, not from the
  /// session. They are chunked in that order, so a pair stays on the board it
  /// was dealt to for as long as the round lasts; re-chunking per read would
  /// move a pair out from under the finger about to press it.
  ///
  /// **Two independent shuffles, and they happen inside the chunk** (BR-127): if
  /// one order drove the other, the board would read straight across and the
  /// answer would be the row number. Shuffling before chunking instead would
  /// re-deal which cards share a board every time the seed changed, which is
  /// every round.
  MatchBoard? buildBoard(
    List<StudyCardModel> cards,
    Random random, {
    int boardIndex = 0,
  }) {
    if (cards.length < kMinMatchPairs) return null;

    final start = boardIndex * kMatchPairsPerBoard;
    if (start >= cards.length) return null;

    final end = start + kMatchPairsPerBoard;
    final onBoard = cards.sublist(
      start,
      end > cards.length ? cards.length : end,
    );

    final terms = <MatchTile>[
      for (final card in onBoard)
        MatchTile(cardId: card.id, text: card.front, isTerm: true),
    ]..shuffle(random);
    final meanings = <MatchTile>[
      for (final card in onBoard)
        MatchTile(cardId: card.id, text: card.back, isTerm: false),
    ]..shuffle(random);

    return MatchBoard(terms: terms, meanings: meanings);
  }
}
