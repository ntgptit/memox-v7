import 'package:flutter/widgets.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_failure_labels_widget.dart';
import '../../../../deck/domain/failures/deck_move_failure.dart';
import '../../../domain/entities/trash_batch_entity.dart';
import '../../../domain/failures/trash_conflict_failure.dart';
import '../../../domain/models/trash_item_type_model.dart';

/// Every user-facing string Trash needs, in one exhaustive place.
///
/// An extension on the build context rather than a widget, for the reason
/// `DeckLabels` gives: this is a mapping from a domain value to copy, and a
/// widget wrapping a `switch` would only add a build to it. Keeping it in
/// `widgets/support/` is deliberate — it is presentation mapping used across
/// buckets, which is exactly what that bucket is for (AD-15).
///
/// **`DeckMoveRejection` gets its own switch here, over the same ARB keys.**
/// BR-261 says restore reuses the move *rule set*, so a restore refused by
/// depth or by scheduler must read the same sentence as a move refused by it —
/// and it does, because both switches resolve to the same `deckMoveReject*`
/// keys. What is not shared is the switch itself: `DeckLabels` lives in the
/// Deck feature's `presentation/`, which no other feature may import (AD-13).
/// The copy has one owner (the ARB entry); only the mapping is written twice,
/// and the compiler keeps both exhaustive.
extension TrashLabels on BuildContext {
  /// Copy for a refusal only Trash can produce (UC-21 E1…E4).
  String trashConflict(TrashConflictReason reason) => switch (reason) {
    TrashConflictReason.targetNoLongerValid =>
      l10n.trashConflictTargetNoLongerValid,
    TrashConflictReason.targetLevelMismatch =>
      l10n.trashConflictTargetLevelMismatch,
    TrashConflictReason.undoOriginUnavailable =>
      l10n.trashConflictUndoOriginUnavailable,
    TrashConflictReason.purgeWouldTakeAnotherBatch =>
      l10n.trashConflictPurgeWouldTakeAnotherBatch,
    TrashConflictReason.unknownItemType => l10n.trashConflictUnknownItemType,
    TrashConflictReason.batchHeightUnknowable =>
      l10n.trashConflictBatchHeightUnknowable,
  };

  /// Why a restore target was refused (UC-09 step 2, reused by BR-261).
  String trashMoveRejection(DeckMoveRejection rejection) => switch (rejection) {
    // Unreachable through restore — a root batch never reaches the move rules
    // (BR-261) — but present because every value must have text.
    DeckMoveRejection.sourceIsRoot => l10n.deckMoveRejectRootDeck,
    DeckMoveRejection.itself => l10n.deckMoveRejectItself,
    DeckMoveRejection.ownDescendant => l10n.deckMoveRejectDescendant,
    // Also unreachable: restoring to the original parent is the normal case,
    // so this rejection is accepted rather than reported.
    DeckMoveRejection.alreadyParent => l10n.deckMoveRejectAlreadyParent,
    DeckMoveRejection.holdsCards => l10n.deckMoveRejectHoldsCards,
    DeckMoveRejection.differentScheduler => l10n.deckMoveRejectScheduler,
    DeckMoveRejection.differentGeneration => l10n.deckMoveRejectGeneration,
    DeckMoveRejection.tooDeep => l10n.deckMoveRejectTooDeep,
  };

  /// A failure from any Trash write, as a sentence.
  String trashWriteFailure(Failure failure) => mxWriteFailure(
    failure,
    // A batch that is gone was purged by a sweep or another screen; the list
    // has already dropped the row, so the message only has to explain why the
    // tap did nothing.
    onNotFound: (_) => l10n.trashConflictTargetNoLongerValid,
    onConflict: (conflict) => switch (conflict.reason) {
      final TrashConflictReason reason => trashConflict(reason),
      final DeckMoveRejection rejection => trashMoveRejection(rejection),
      _ => l10n.writeErrorMessage,
    },
  );

  /// Anything thrown by a command, including what is not a [Failure].
  ///
  /// A controller returns the error rather than throwing it, so this is where a
  /// non-`Failure` would arrive. There is one honest thing to say about it.
  String trashCommandError(Object error) =>
      error is Failure ? trashWriteFailure(error) : l10n.writeErrorMessage;

  /// The original path, as a single line of context (BR-267, wireframe T5).
  ///
  /// **Not a destination, and it must not read like one.** The screen renders
  /// this after `trashOriginLabel` with no affordance; a deleted top-level deck
  /// has no parent at all and says so rather than showing an empty line.
  String trashOriginPath(TrashBatchEntity batch) {
    final names = <String>[
      for (final segment in batch.originPath) segment.name,
    ];
    if (batch.originDeckName != null) names.add(batch.originDeckName!);
    if (names.isEmpty) return l10n.trashOriginTopLevel;

    // A thin space either side of the separator, so the chain reads as a path
    // at any text scale rather than as one long word that cannot wrap.
    return names.join(' › ');
  }

  /// What a deck batch would bring back (BR-262).
  String trashBatchContents(TrashBatchEntity batch) => l10n.trashBatchContents(
    // The item root is one of the decks the batch marked, and the row already
    // names it — so the number beside it counts what *comes with* it.
    batch.deckCount > 0 ? batch.deckCount - 1 : 0,
    batch.cardCount,
  );

  /// The icon that tells the two kinds apart at a glance.
  String trashItemTypeLabel(TrashItemType type) => switch (type) {
    TrashItemType.card => l10n.trashFilterCards,
    TrashItemType.deck => l10n.trashFilterDecks,
  };
}
