import '../entities/deck_entity.dart';
import '../repositories/deck_repository.dart';

/// A deck's direct children (UC-06 step 4, UC-08).
///
/// One interaction, one method. Reading the deck itself is
/// [GetDeckByIdUseCase] — they were one class until the method count made the
/// point, and a use case with two queries is the same shape as a notifier with
/// eight, only smaller.
class WatchDeckChildrenUseCase {
  const WatchDeckChildrenUseCase(this._repository);

  final DeckRepository _repository;

  Stream<List<DeckEntity>> call(String parentDeckId) =>
      _repository.watchChildDecks(parentDeckId);
}
