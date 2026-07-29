import 'package:freezed_annotation/freezed_annotation.dart';

part 'deck_deletion_impact_model.freezed.dart';

/// What deleting a deck would take with it (BR-03, BR-04).
///
/// The confirm dialog in UC-03 shows both numbers before anything is deleted;
/// this is the value it renders.
@freezed
abstract class DeckDeletionImpact with _$DeckDeletionImpact {
  const factory DeckDeletionImpact({
    /// Sub-decks below the deck, at every depth. Excludes the deck itself.
    required int descendantDeckCount,

    /// Cards in the deck and its whole subtree.
    required int cardCount,
  }) = _DeckDeletionImpact;
}
