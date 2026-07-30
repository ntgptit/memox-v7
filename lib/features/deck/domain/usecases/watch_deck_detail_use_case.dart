import '../models/deck_detail_model.dart';
import '../repositories/deck_repository.dart';

/// Watches one deck together with its direct children (UC-06 step 4, UC-08).
///
/// **One interaction, and one read.** "One use case per interaction" does not mean
/// one SQL statement per use case — it means one *thing the user is doing*. Opening
/// a deck is one thing, and the screen needs the deck and its children as a pair,
/// so they come from a single statement and a single snapshot.
///
/// This replaced a controller that watched the children and then asked for the deck
/// per emission. That version could show a deck and a child list captured at
/// different instants, and the window was real: a rename or a create lands between
/// the two reads.
///
/// A deck that does not exist surfaces as a `NotFoundFailure` on the stream, which
/// the screen renders as a way back rather than a retry (UC-03 E1).
class WatchDeckDetailUseCase {
  const WatchDeckDetailUseCase(this._repository);

  final DeckRepository _repository;

  Stream<DeckDetail> call(String deckId) => _repository.watchDeckDetail(deckId);
}
