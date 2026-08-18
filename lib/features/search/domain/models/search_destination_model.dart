import 'search_result_model.dart';

/// Where tapping a result leads, named without naming a route (BR-254).
///
/// **A typed seam rather than a `goNamed` inside a row.** Card Detail does not
/// exist on this base: it is a separate feature on a separate branch, and this
/// one must not grow a second detail screen to fill the gap, nor quietly send
/// the user to the *editor* — a search is a read, and landing in an edit form
/// from a read is how content gets changed by accident.
///
/// So a row reports a destination and something else decides what to do with
/// it. `search_navigation_provider.dart` binds the decision; the domain, the
/// data layer and the widgets compile and are tested without any route existing
/// for [CardDestination] at all.
///
/// Sealed, so the day Card Detail lands the compiler names every place that has
/// to learn about it.
sealed class SearchDestination {
  const SearchDestination();

  /// The destination a hit leads to. One function rather than a `switch` at each
  /// call site, so a third kind of hit cannot reach a row that forgot it.
  static SearchDestination of(LibrarySearchHit hit) => switch (hit) {
    DeckSearchHit(:final String deckId) => DeckDestination(deckId: deckId),
    CardSearchHit(:final String cardId, :final String deckId) =>
      CardDestination(cardId: cardId, deckId: deckId),
  };
}

/// One deck's contents. Real on this base — the deck route exists.
final class DeckDestination extends SearchDestination {
  const DeckDestination({required this.deckId});

  final String deckId;

  @override
  bool operator ==(Object other) =>
      other is DeckDestination && other.deckId == deckId;

  @override
  int get hashCode => deckId.hashCode;

  @override
  String toString() => 'DeckDestination($deckId)';
}

/// One card, read-only.
///
/// **Carries the deck as well as the card**, because every card route in this
/// app is nested under its deck, so a destination holding only a card id could
/// not be turned into a location without a database read. The dependency this
/// records is the *route*, not the data.
final class CardDestination extends SearchDestination {
  const CardDestination({required this.cardId, required this.deckId});

  final String cardId;
  final String deckId;

  @override
  bool operator ==(Object other) =>
      other is CardDestination &&
      other.cardId == cardId &&
      other.deckId == deckId;

  @override
  int get hashCode => Object.hash(cardId, deckId);

  @override
  String toString() => 'CardDestination($cardId in $deckId)';
}
