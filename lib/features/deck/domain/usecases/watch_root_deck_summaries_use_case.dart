import '../models/root_deck_summary_model.dart';
import '../repositories/deck_repository.dart';

/// Every root deck with its aggregate progress (UC-06 step 1).
class WatchRootDeckSummariesUseCase {
  const WatchRootDeckSummariesUseCase(this._repository);

  final DeckRepository _repository;

  /// [now] is a parameter, never a clock read in here: the caller decides which
  /// instant the due counts are measured against, and a use case that read the
  /// clock itself could not be tested at the `due_at == now` boundary.
  Stream<List<RootDeckSummary>> call({required DateTime now}) =>
      _repository.watchRootDeckSummaries(now: now);
}
