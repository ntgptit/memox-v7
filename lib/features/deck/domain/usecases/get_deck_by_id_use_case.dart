import '../entities/deck_entity.dart';
import '../repositories/deck_repository.dart';

/// One deck, by id.
///
/// Split out of `WatchDeckChildrenUseCase`, which held this alongside the
/// children stream. Reading a deck and watching its children are two
/// interactions, and a use case that does two is the shape "one use case per
/// interaction" exists to prevent — in miniature, but the same shape a
/// `DeckNotifier` with eight methods grows from.
///
/// Composing them is the *controller's* job: `deckDetail` builds the screen's
/// read model from both, which is what a controller is for.
class GetDeckByIdUseCase {
  const GetDeckByIdUseCase(this._repository);

  final DeckRepository _repository;

  Future<DeckEntity> call(String deckId) => _repository.getDeckById(deckId);
}
