import 'package:freezed_annotation/freezed_annotation.dart';

part 'deck_activity_metrics_model.freezed.dart';

/// What one deck's subtree amounts to inside one window (BR-193…BR-196).
///
/// **Four figures, and only four.** Accuracy, score, streak and due forecast are
/// deliberately out of v1 (BR-192): each needs its own definition argument, and
/// a screen that ships five half-agreed numbers teaches nobody to trust any of
/// them.
///
/// **Two of the four are counts of cards and days; two are counts of card-days.**
/// They do not measure the same thing and must never be added together:
/// [activeCardCount] answers "how much of the deck did I touch", [activeDayCount]
/// answers "how often did I show up", and the Learning/Reviewing pair splits the
/// work itself. The pair is exhaustive and exclusive by construction (BR-196),
/// which is what [cardDayCount] leans on.
@freezed
abstract class DeckActivityMetrics with _$DeckActivityMetrics {
  const factory DeckActivityMetrics({
    /// Distinct cards answered at least once in the window (BR-193).
    required int activeCardCount,

    /// Distinct local days on which at least one card was answered (BR-193).
    ///
    /// Never larger than the window's `dayCount`, and it does **not** add up
    /// across sibling decks: the same Tuesday can be active in two decks and is
    /// still one day of study. Every total is therefore read, never summed.
    required int activeDayCount,

    /// Card-days whose day contained at least one `learning` turn (BR-196).
    required int learningCardDayCount,

    /// Card-days with no `learning` turn — `scheduled` and `relearning` alike
    /// (BR-196).
    required int reviewingCardDayCount,
  }) = _DeckActivityMetrics;

  const DeckActivityMetrics._();

  /// Nothing happened here in this window.
  static const DeckActivityMetrics zero = DeckActivityMetrics(
    activeCardCount: 0,
    activeDayCount: 0,
    learningCardDayCount: 0,
    reviewingCardDayCount: 0,
  );

  /// Every card-day in the window: the two halves of the partition, summed.
  ///
  /// Safe to add precisely because the two are exclusive and exhaustive
  /// (BR-196) — a card-day is one or the other, never both and never neither.
  int get cardDayCount => learningCardDayCount + reviewingCardDayCount;

  /// Whether this deck was touched at all in the window.
  ///
  /// Reads [activeCardCount] rather than [cardDayCount]: they agree by
  /// construction, and the card count is the figure the sort and the empty
  /// state both speak (BR-197).
  bool get hasActivity => activeCardCount > 0;
}
