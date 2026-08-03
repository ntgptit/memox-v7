import '../repositories/card_repository.dart';

/// Whether a deck holds cards (BR-63) — the fact the router's auto-forward reads
/// before deciding to redirect a deck's detail route into its card list (UC-04).
///
/// A one-shot, not a stream: the redirect asks once per navigation and does not
/// stay subscribed. Thin — the repository owns the content-type read.
class ReadDeckHoldsCardsUseCase {
  const ReadDeckHoldsCardsUseCase(this._repository);

  final CardRepository _repository;

  Future<bool> call(String deckId) => _repository.readDeckHoldsCards(deckId);
}
