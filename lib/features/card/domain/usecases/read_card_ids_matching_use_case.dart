import '../models/card_list_filter_model.dart';
import '../repositories/card_repository.dart';

/// The ids a deck's list currently matches — what Select all selects (BR-167).
///
/// **A read that returns ids, not cards.** The selection is a set of strings;
/// loading every front and back to build it would carry the whole deck across
/// the isolate boundary for a question the database can answer in one column.
///
/// The filter and search term are the screen's live ones, so "all" means what
/// the user is looking at rather than everything in the deck.
class ReadCardIdsMatchingUseCase {
  const ReadCardIdsMatchingUseCase(this._repository);

  final CardRepository _repository;

  Future<List<String>> call(
    String deckId, {
    CardListFilter filter = CardListFilter.all,
    String? searchTerm,
    DateTime? now,
  }) => _repository.readCardIdsMatching(
    deckId,
    filter: filter,
    searchTerm: searchTerm,
    now: now,
  );
}
