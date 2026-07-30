import 'package:freezed_annotation/freezed_annotation.dart';

import 'root_deck_summary_model.dart';

part 'root_deck_list_snapshot_model.freezed.dart';

/// The root deck list, and the instant its due counts stop being true.
///
/// **Why the boundary travels with the counts.** Every `dueCardCount` in [decks]
/// is relative to the `now` the read was given (BR-22), so each one has an expiry:
/// the earliest `due_at` still in the future. The screen re-measures at that
/// instant. Reading the boundary separately would compute it from a different
/// database state than the counts, and the refresh would then land at a moment
/// that was correct for neither — so both come from one statement.
///
/// This is what fixed a real staleness bug rather than a theoretical one. The list
/// used to re-measure only when the app returned to the foreground, on the
/// reasoning that hours pass in a pocket. They do — but a user can also sit on
/// this screen while a card comes due, and until then the badge said 3 while the
/// session it launches handed out 4. That reads as a scheduler bug and is not one.
@freezed
abstract class RootDeckListSnapshot with _$RootDeckListSnapshot {
  const factory RootDeckListSnapshot({
    required List<RootDeckSummary> decks,

    /// The earliest instant strictly after the read's `now` at which some card
    /// becomes due, or `null` when no card is scheduled to.
    ///
    /// `null` is a real state with two causes — no cards at all, or every card
    /// already due — and both mean the same thing to the caller: there is nothing
    /// to wait for, so do not wait.
    required DateTime? nextDueAt,
  }) = _RootDeckListSnapshot;

  const RootDeckListSnapshot._();

  bool get isEmpty => decks.isEmpty;
}
