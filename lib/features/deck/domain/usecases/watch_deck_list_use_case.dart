import '../models/deck_list_snapshot_model.dart';
import '../repositories/deck_repository.dart';

/// Watches one level of the deck tree (UC-06, UC-08).
///
/// **One use case, because the user is doing one thing.** Opening a deck is not a
/// different activity from looking at the deck list — it is the same activity one
/// level down. This replaced `WatchRootDeckListUseCase` and
/// `WatchDeckDetailUseCase`, which described that one activity twice and answered
/// it with different amounts of information: the root list had counts, the inside
/// of a deck had names.
///
/// [parentDeckId] null is the root level. Any other id is the inside of that deck,
/// and the snapshot carries the deck itself so the screen can name itself from the
/// same read the list came from.
///
/// [now] is a parameter, never a clock read in here: the caller decides which
/// instant the due counts are measured against, and a use case that read the clock
/// itself could not be tested at the `due_at == now` boundary.
class WatchDeckListUseCase {
  const WatchDeckListUseCase(this._repository);

  final DeckRepository _repository;

  Stream<DeckListSnapshot> call({
    required String? parentDeckId,
    required DateTime now,
  }) => _repository.watchDeckList(parentDeckId: parentDeckId, now: now);
}
