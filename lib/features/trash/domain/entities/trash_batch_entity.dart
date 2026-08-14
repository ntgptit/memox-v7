import '../models/trash_item_type_model.dart';
import '../models/trash_retention_model.dart';

/// One segment of the path an item was deleted from (BR-193).
///
/// **Information, never a destination.** The path is where the item *was*; where
/// it goes back to is whatever target the user picks (BR-187). The two are
/// deliberately different types so a screen cannot pass one where the other
/// belongs.
final class TrashPathSegment {
  const TrashPathSegment({required this.deckId, required this.name});

  final String deckId;
  final String name;
}

/// One deletion, as Trash shows it (BR-182, UC-12).
///
/// The unit is the **batch**, not the row: a deck deletion marks a whole
/// subtree and the user restores or purges it as the one thing they deleted.
///
/// Immutable, and every field is a fact read in one snapshot — the counts, the
/// name and the path all come from `trashBatchRows`, so a row can never show a
/// count from before a write beside a name from after it (AD-13).
final class TrashBatchEntity {
  const TrashBatchEntity({
    required this.batchId,
    required this.itemType,
    required this.itemName,
    required this.deletedAt,
    required this.originDeckId,
    required this.originDeckName,
    required this.originPath,
    required this.deckCount,
    required this.cardCount,
  });

  final String batchId;
  final TrashItemType itemType;

  /// The deck's name, or the card's front. Displayed, never logged (BR-193).
  final String itemName;

  final DateTime deletedAt;

  /// The deck the item sat in when it was deleted, or null for a root deck.
  ///
  /// A root has no parent (BR-56), which is also why its only restore target is
  /// the top level.
  final String? originDeckId;

  /// The origin deck's own name, null for a root deck.
  final String? originDeckName;

  /// Root-first, and **excluding** the origin deck itself; the screen renders
  /// the chain and then [originDeckName] last.
  final List<TrashPathSegment> originPath;

  /// How many decks and cards this batch would bring back (BR-188).
  ///
  /// A descendant already in Trash under an older batch is in neither count —
  /// restoring this batch leaves it where it is (BR-184), and the confirm
  /// dialog must say what actually moves.
  final int deckCount;
  final int cardCount;

  /// Whether the item root is a root deck, and therefore restorable only to the
  /// top level (BR-187).
  ///
  /// Derived from the absence of an origin deck rather than stored: a deck with
  /// no parent *is* a root (BR-56), and storing a second answer to that would
  /// be a second thing that can be wrong.
  bool get isRootDeck => itemType == TrashItemType.deck && originDeckId == null;

  DateTime get expiresAt => TrashRetention.expiryOf(deletedAt);

  int daysLeftAt(DateTime now) =>
      TrashRetention.daysLeft(deletedAt: deletedAt, now: now);

  bool isExpiredAt(DateTime now) =>
      TrashRetention.isExpired(deletedAt: deletedAt, now: now);
}
