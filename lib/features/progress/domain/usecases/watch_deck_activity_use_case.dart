import '../models/deck_activity_snapshot_model.dart';
import '../repositories/progress_repository.dart';

/// Watches one level of Progress by Deck (UC-13).
///
/// **One use case, because looking at a deck's progress and looking at the whole
/// library's progress are the same activity one level apart** — the same
/// argument `WatchDeckListUseCase` makes for the deck tree. Two use cases would
/// be two chances for the top level and a drilled level to answer with different
/// amounts of information, which is exactly how the deck feature ended up with
/// two screens for one idea.
///
/// Thin, and deliberately so (AD-12): there is no input to validate and no rule
/// to apply above the read, because every rule this feature has needs the data as
/// it stands at the moment of reading and therefore belongs in the statement.
/// The use case exists so `presentation/` never names a repository.
class WatchDeckActivityUseCase {
  const WatchDeckActivityUseCase(this._repository);

  final ProgressRepository _repository;

  Stream<DeckActivitySnapshot> call({
    required String? deckId,
    required DateTime now,
    required Duration utcOffset,
  }) => _repository.watchDeckActivity(
    deckId: deckId,
    now: now,
    utcOffset: utcOffset,
  );
}
