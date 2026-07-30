import '../failures/deck_validation_failure.dart';
import '../repositories/deck_repository.dart';

/// Renames a deck (UC-03, BR-01).
///
/// Works for a root and a sub-deck alike: a rename touches the name and
/// `updated_at` and nothing else — not the scheduler, not the content type, not
/// the tree.
class RenameDeckUseCase {
  const RenameDeckUseCase(this._repository);

  final DeckRepository _repository;

  Future<void> call({required String deckId, required String name}) {
    refuseInvalidDeckForm(<String, String>{...?deckNameFieldError(name)});

    return _repository.renameDeck(deckId: deckId, name: name);
  }
}
