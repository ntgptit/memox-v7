import '../models/study_deck_context_model.dart';
import '../repositories/study_repository.dart';

/// Reads the deck a study surface is scoped to — its name, its root, and the
/// algorithm that root locked in.
///
/// **Thin, and that is the accepted cost** (AD-12). It applies no rule; every
/// interaction gets a use case so a new feature is a clone rather than a
/// judgement call at each operation, and so a controller never reaches for a
/// repository. Six of Deck's ten carry real validation and four are exactly
/// this shape.
///
/// **One read, not two, and that is not the same read as the counts.**
/// `StudyEntrySummaryModel` deliberately carries no deck name: the counts are a
/// `watch()` stream over card state and the name is a property of the deck row,
/// so folding the name into the count query would make every answered card
/// re-emit the deck's name. Card list titles from its own deck-context read for
/// the same reason (SC-C9-15).
class GetStudyDeckContextUseCase {
  const GetStudyDeckContextUseCase(this._repository);

  final StudyRepository _repository;

  Future<StudyDeckContextModel> call(String deckId) =>
      _repository.deckContext(deckId);
}

/// The same context, as a live read.
///
/// **The screen's copy has to be the watching one.** The one-shot form left the
/// study entry title naming a deck by its old name after a rename made
/// anywhere but this screen's own options round-trip, because
/// `StatefulShellRoute.indexedStack` keeps the Study branch mounted — nothing
/// disposes the provider, so nothing re-runs the read. The screen answered that
/// with a manual `ref.invalidate` in `_refresh()`, which only fires on one
/// path out of many.
///
/// `WatchDeckContextUseCase` in the card feature is the same shape for the same
/// reason, and needs no invalidate anywhere.
class WatchStudyDeckContextUseCase {
  const WatchStudyDeckContextUseCase(this._repository);

  final StudyRepository _repository;

  Stream<StudyDeckContextModel> call(String deckId) =>
      _repository.watchDeckContext(deckId);
}
