import 'package:freezed_annotation/freezed_annotation.dart';

import '../entities/deck_entity.dart';

part 'root_deck_summary_model.freezed.dart';

/// One row of the root deck list: a deck plus the two numbers UC-06 shows
/// beside it.
///
/// A read model, not an entity. It exists because the screen needs three facts
/// at once and the aggregate that produces them is a single query (BR-56 makes
/// a flat `GROUP BY` possible); putting the counts on [DeckEntity] would put
/// numbers that are only true at one instant onto the type every write path
/// also uses.
///
/// [dueCardCount] is relative to the `now` the query was given (BR-22). It is
/// therefore a snapshot, and the provider that produces it re-reads when the
/// clock crosses a boundary — a stale count on this screen would disagree with
/// the session the user then starts, which reads as a scheduler bug and is not
/// one.
@freezed
abstract class RootDeckSummary with _$RootDeckSummary {
  const factory RootDeckSummary({
    required DeckEntity deck,

    /// Cards anywhere in this root's tree, at any depth.
    required int totalCardCount,

    /// Of those, how many were due at the `now` used for the read (BR-22).
    required int dueCardCount,
  }) = _RootDeckSummary;

  const RootDeckSummary._();

  /// Whether anything is waiting to be studied.
  ///
  /// A predicate rather than letting each widget compare against zero: BR-29
  /// says "nothing due" is a normal state and not an error, and a screen that
  /// re-derives the comparison in three places is a screen where one of them
  /// eventually renders it as a warning.
  bool get hasDueCards => dueCardCount > 0;
}
