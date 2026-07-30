import '../models/deck_deletion_impact_model.dart';
import '../repositories/deck_repository.dart';

/// What deleting a deck would take with it (UC-03, BR-04).
///
/// A separate read rather than a field on the deck, because the confirmation is
/// not allowed to state a number it does not have.
class GetDeckDeletionImpactUseCase {
  const GetDeckDeletionImpactUseCase(this._repository);

  final DeckRepository _repository;

  Future<DeckDeletionImpact> call(String deckId) =>
      _repository.getDeletionImpact(deckId);
}
