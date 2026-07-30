import '../../../../core/error/failure.dart';
import '../entities/deck_entity.dart';
import '../models/deck_move_target_model.dart';
import '../repositories/deck_repository.dart';

/// Every candidate destination for a move, each with a reason when it is not
/// eligible (UC-09 step 2).
///
/// **One read per emission, not two.** `watchAllDecks` is unfiltered by contract,
/// so the deck being moved is already in the list — asking the repository for it
/// again would be a second query answering a question the emission has already
/// answered, and answering it from a *later* snapshot. That is the bug the
/// N+1-avoiding design was supposed to rule out, one level up: the source could
/// come from after a write while the candidate list came from before it, and
/// `buildDeckMoveTargets` would then compute depth and subtree membership from
/// two different trees.
///
/// The rule itself is the same function `moveDeck` applies, so what the picker
/// offers and what the write accepts cannot disagree.
class WatchDeckMoveTargetsUseCase {
  const WatchDeckMoveTargetsUseCase(this._repository);

  final DeckRepository _repository;

  Stream<List<DeckMoveTarget>> call(String deckId) =>
      _repository.watchAllDecks().map(
        (List<DeckEntity> decks) => buildDeckMoveTargets(
          source: _requireSource(decks, deckId),
          allDecks: decks,
        ),
      );

  /// The deck being moved, taken from the snapshot the targets are built from.
  ///
  /// Absent means it was deleted from another screen while the picker was open —
  /// a typed [NotFoundFailure] so the picker closes with a way back rather than
  /// showing a list of destinations for a deck that no longer exists.
  static DeckEntity _requireSource(List<DeckEntity> decks, String deckId) {
    for (final DeckEntity deck in decks) {
      if (deck.id == deckId) return deck;
    }

    throw const NotFoundFailure(message: 'That deck no longer exists.');
  }
}
