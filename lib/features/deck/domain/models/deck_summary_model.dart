import 'package:freezed_annotation/freezed_annotation.dart';

import '../entities/deck_entity.dart';
import 'scheduler_type_model.dart';

part 'deck_summary_model.freezed.dart';

/// One deck in a list, with the numbers shown beside it (UC-06).
///
/// A read model, not an entity. It exists because a row needs several facts at
/// once and the aggregate that produces them is a single query; putting the
/// counts on [DeckEntity] would put numbers that are only true at one instant
/// onto the type every write path also uses.
///
/// **The same type at every level.** It was `DeckSummary` while only the root
/// list had counts, and opening a deck then showed a plainer list — names with no
/// numbers — because the read underneath returned bare rows. That difference was
/// never a design decision; it was the shape of the data leaking into the UI. A
/// deck is a deck, so one summary type describes it wherever it appears.
@freezed
abstract class DeckSummary with _$DeckSummary {
  const factory DeckSummary({
    required DeckEntity deck,

    /// Cards anywhere in this deck's subtree, at any depth.
    required int totalCardCount,

    /// Of those, how many were due at the `now` used for the read (BR-22).
    required int dueCardCount,

    /// The scheduler this deck is reviewed with — **resolved**, not raw.
    ///
    /// A sub-deck's own scheduler columns are NULL by rule (BR-06); the review it
    /// takes part in uses its root's. Reading `deck.schedulerType` would show
    /// nothing for every deck below the first level, so the resolved value is a
    /// field of its own and the raw column stays where it belongs.
    required SchedulerType schedulerType,
  }) = _DeckSummary;

  const DeckSummary._();

  /// Whether anything is waiting to be studied.
  ///
  /// A predicate rather than letting each widget compare against zero: BR-29 says
  /// "nothing due" is a normal state and not an error, and a screen that
  /// re-derives the comparison in three places is a screen where one of them
  /// eventually renders it as a warning.
  bool get hasDueCards => dueCardCount > 0;
}
