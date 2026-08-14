import '../models/deck_activity_snapshot_model.dart';

/// The read side of Progress by Deck (UC-12).
///
/// **Read-only, and the contract says so by having nothing else on it** (BR-188).
/// Opening a progress screen must not touch a schedule, close a session or stamp
/// a row: a person looking at what they did is not doing anything. A repository
/// with a single `watch` cannot break that by accident.
abstract interface class ProgressRepository {
  /// One level of the tree, live.
  ///
  /// [deckId] null is the top level — every root deck, and the totals across all
  /// of them. Any other id is that deck's own level: its direct children, and
  /// the totals across its whole subtree.
  ///
  /// The stream re-emits whenever an answer, a card or a deck changes, so a
  /// review graded elsewhere, a card moved into this deck and a deck deleted all
  /// land without the screen asking (BR-189).
  ///
  /// [now] and [utcOffset] are parameters, never read in here: the caller
  /// decides which instant the windows are measured against and which zone
  /// decides where a day starts. A repository that read either could not be
  /// tested at the 23:59 boundary, and that boundary is where every windowed
  /// metric is wrong or right.
  ///
  /// Emits a `NotFoundFailure` when [deckId] names a deck that does not exist —
  /// a deleted deck's link must fail, not render an empty level.
  Stream<DeckActivitySnapshot> watchDeckActivity({
    required String? deckId,
    required DateTime now,
    required Duration utcOffset,
  });
}
