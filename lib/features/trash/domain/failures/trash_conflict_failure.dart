/// Why a Trash operation was refused, as a value instead of a sentence.
///
/// Same contract as `DeckConflictReason`: `Failure.message` is a sanitized
/// diagnostic the UI must not render, so every refusal a user can act on needs
/// its own value here and its own copy in the labels extension. A reason added
/// to this enum fails to compile until it has text.
///
/// **Restore's *target* rejections are not here.** Those are
/// `DeckMoveRejection`, thrown unchanged, because BR-261 says restore uses the
/// move rule set and a parallel enum would be the second spelling that drifts.
/// What is here is what only Trash can refuse.
enum TrashConflictReason {
  /// The chosen target is not one the picker would have offered — a card batch
  /// aimed at a root, a deck batch aimed at a deck holding cards, or a target
  /// that stopped qualifying between the picker opening and the confirm
  /// (UC-21 E2).
  targetNoLongerValid,

  /// A **root** deck batch was aimed at a deck, or a non-root batch at the top
  /// level (BR-261). A root has no parent, and nothing else may become one.
  targetLevelMismatch,

  /// Undo was pressed after the original location stopped qualifying — deleted,
  /// turned into a card deck, or now at the depth limit (BR-263, UC-21 E3).
  ///
  /// Distinct from [targetNoLongerValid] because the user chose nothing here:
  /// the copy has to point them at Trash rather than at a picker.
  undoOriginUnavailable,

  /// A purge would have cascaded into a batch that is not itself eligible, or
  /// into rows that are still active (BR-265, UC-21 E4).
  purgeWouldTakeAnotherBatch,

  /// The batch's stored `item_type` is a value this build does not know — it
  /// was written by a newer version. Refused rather than guessed at, for the
  /// same reason `unknownContentType` is.
  unknownItemType,

  /// The subtree is taller than the walk bound allows, so where it may land
  /// cannot be established. Same reasoning as `subtreeHeightUnknowable`: refuse
  /// rather than answer with a number that might be wrong.
  batchHeightUnknowable,
}
