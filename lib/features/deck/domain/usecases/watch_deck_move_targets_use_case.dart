import '../models/deck_move_target_model.dart';
import '../repositories/deck_repository.dart';

/// Every candidate destination for a move, each with a reason when it is not
/// eligible (UC-09 step 2).
///
/// One repository read for the whole tree, then the pure rule per candidate.
/// Asking per candidate instead is the N+1 the picker exists to avoid, and the
/// rule is the same function `moveDeck` applies — so what the picker offers and
/// what the write accepts cannot disagree.
class WatchDeckMoveTargetsUseCase {
  const WatchDeckMoveTargetsUseCase(this._repository);

  final DeckRepository _repository;

  Stream<List<DeckMoveTarget>> call(
    String deckId,
  ) => _repository.watchAllDecks().asyncMap(
    (decks) async => buildDeckMoveTargets(
      // The source is read per emission rather than once, so a rename or a
      // move landing while the picker is open is reflected in what it offers.
      source: await _repository.getDeckById(deckId),
      allDecks: decks,
    ),
  );
}
