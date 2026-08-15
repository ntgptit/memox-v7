import '../models/deck_activity_snapshot_model.dart';
import '../models/progress_overview_model.dart';

/// Reading the learner's own activity back out of history (UC-12, UC-13).
///
/// **Read-only, and the contract says so by having nothing else on it**
/// (BR-190, BR-198). Opening a progress screen must not touch a schedule, close
/// a session or stamp a row: a person looking at what they did is not doing
/// anything. A contract with nothing but `watch` methods cannot break that by
/// accident, and adding a write would be a visible decision in this file rather
/// than a line inside an implementation.
///
/// **Two reads, not one, and they are not composable into one.** The overview
/// answers "how am I doing" for the whole library and needs no deck; the level
/// read answers "where did it go" for one node of the tree and is parameterised
/// by it. A single method taking a nullable deck id would return a different
/// shape depending on that argument, which is two methods wearing one name.
///
/// Both take their instant and their zone as parameters (AD-16, BR-184,
/// BR-194). Nothing under `lib/features/` reads the wall clock, and a repository
/// that did could not be tested at a local-midnight boundary — which is the
/// boundary every number here is defined against.
abstract interface class ProgressRepository {
  /// One consistent snapshot per emission, re-emitted whenever the history it
  /// summarises changes (BR-199).
  ///
  /// [now] and [utcOffset] are one snapshot of `clockProvider` and
  /// `utcOffsetProvider`, taken by the caller. Crossing local midnight is a new
  /// [now], not an event the repository detects: the stream measures what it is
  /// asked to measure, and the controller decides when to ask again.
  Stream<ProgressOverview> watchProgressOverview({
    required DateTime now,
    required Duration utcOffset,
  });

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
  /// Emits a `NotFoundFailure` when [deckId] names a deck that does not exist —
  /// a deleted deck's link must fail, not render an empty level.
  Stream<DeckActivitySnapshot> watchDeckActivity({
    required String? deckId,
    required DateTime now,
    required Duration utcOffset,
  });
}
