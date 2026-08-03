import 'card_state_model.dart';

/// How a deck's cards spread across the four display states, for the progress
/// panel (D5, BR-88…BR-91).
///
/// **Whole-deck, not the window.** The list holds a page; this describes every
/// card, so it comes from the `cardStateCountsByDeck` aggregate rather than from
/// counting the rows on screen — see `card.drift`.
class CardStateDistributionModel {
  const CardStateDistributionModel({
    required this.total,
    required this.isNew,
    required this.beginning,
    required this.reviewing,
    required this.mastered,
  });

  final int total;
  final int isNew;
  final int beginning;
  final int reviewing;
  final int mastered;

  /// The fraction mastered, for the ring (BR-88). Zero for an empty deck rather
  /// than a divide-by-zero.
  double get masteredFraction => total == 0 ? 0 : mastered / total;

  /// The count for one display state — so a legend can iterate the enum instead
  /// of naming four fields.
  int countOf(CardState state) => switch (state) {
    CardState.isNew => isNew,
    CardState.beginning => beginning,
    CardState.reviewing => reviewing,
    CardState.mastered => mastered,
  };
}
