import '../entities/deck_entity.dart';
import '../repositories/deck_repository.dart';

/// A deck and its direct children (UC-06 step 4, UC-08).
///
/// Two calls rather than one composed stream, because the screen needs them at
/// different times: the deck to title the shell, the children to fill it.
class WatchDeckChildrenUseCase {
  const WatchDeckChildrenUseCase(this._repository);

  final DeckRepository _repository;

  Stream<List<DeckEntity>> call(String parentDeckId) =>
      _repository.watchChildDecks(parentDeckId);

  Future<DeckEntity> deck(String deckId) => _repository.getDeckById(deckId);
}
