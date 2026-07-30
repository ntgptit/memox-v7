import '../failures/deck_validation_failure.dart';
import '../models/deck_name_model.dart';
import '../repositories/deck_repository.dart';

/// Renames a deck (UC-03, BR-01).
///
/// Works for a root and a sub-deck alike: a rename touches the name and
/// `updated_at` and nothing else — not the scheduler, not the content type, not
/// the tree.
class RenameDeckUseCase {
  const RenameDeckUseCase(this._repository);

  final DeckRepository _repository;

  Future<void> call({required String deckId, required String rawName}) {
    final parsed = DeckName.parse(rawName);
    refuseInvalidDeckForm(<DeckValidationProblem>{?parsed.problem});
    final name = parsed.name;
    if (name == null) {
      throw StateError('unreachable: refuseInvalidDeckForm would have thrown');
    }

    return _repository.renameDeck(deckId: deckId, name: name);
  }
}
