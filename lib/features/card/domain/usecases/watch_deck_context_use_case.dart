import '../models/deck_context_model.dart';
import '../repositories/card_repository.dart';

/// The card list header: the deck's name and ancestor breadcrumb (UC-04, W1).
///
/// Thin, like the other reads. The repository shapes the one snapshot so the
/// title and the breadcrumb cannot disagree; this use case forwards it.
class WatchDeckContextUseCase {
  const WatchDeckContextUseCase(this._repository);

  final CardRepository _repository;

  Stream<DeckContextModel> call(String deckId) =>
      _repository.watchDeckContext(deckId);
}
