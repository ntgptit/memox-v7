import '../models/root_deck_list_snapshot_model.dart';
import '../repositories/deck_repository.dart';

/// Every root deck with its aggregate progress, and when that progress expires
/// (UC-06 step 1).
///
/// Named for what it returns. It was `WatchRootDeckListUseCase` while it
/// returned a list of summaries; it now returns the list *and* the instant the
/// counts stop being true, because the screen needs both to know when to ask
/// again — and a name that described half of that would be the sort of small lie
/// a template propagates.
class WatchRootDeckListUseCase {
  const WatchRootDeckListUseCase(this._repository);

  final DeckRepository _repository;

  /// [now] is a parameter, never a clock read in here: the caller decides which
  /// instant the due counts are measured against, and a use case that read the
  /// clock itself could not be tested at the `due_at == now` boundary.
  Stream<RootDeckListSnapshot> call({required DateTime now}) =>
      _repository.watchRootDeckList(now: now);
}
