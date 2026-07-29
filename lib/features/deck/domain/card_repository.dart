import 'card_entity.dart';

/// Contract for card management inside a deck (UC-04, UC-08).
///
/// Split from `DeckRepository` (M4.9a): deck-tree management and card CRUD
/// are different responsibilities, and M5 grows the card side further. Like
/// its sibling, this contract is written from what presentation needs — no
/// method accepts or returns a Drift row, companion or DAO type, and no
/// Drift/SQLite exception escapes an implementation; failures surface as the
/// domain `Failure` hierarchy (`ValidationFailure`, `NotFoundFailure`,
/// `ConflictFailure`, `DatabaseFailure`).
///
/// Creating a card deliberately crosses into deck state — it validates the
/// target deck, locks an `unset` deck to `card` (BR-62) and resolves the
/// scheduler from the root (BR-09). That cross-entity invariant belongs to
/// the card operation's implementation; it does not make card CRUD a deck
/// responsibility.
abstract interface class CardRepository {
  /// The cards of one deck, re-emitted on every change (AD-01).
  Stream<List<CardEntity>> watchCardsByDeck(String deckId);

  /// Creates a card and exactly one review state atomically — BR-09, BR-62.
  /// The state carries the root's scheduler, version and current generation,
  /// `due_at = NULL`, and the scheduler's initial values; a deck still
  /// `unset` becomes `card` in the same atomic step.
  Future<CardEntity> createCard({
    required String deckId,
    required String front,
    required String back,
  });

  /// Updates card content only (BR-10) — the review state and history are
  /// untouched, structurally, because this writes only to `cards`.
  Future<CardEntity> updateCard({
    required String cardId,
    required String front,
    required String back,
  });

  /// Deletes a card; its review state and history cascade. The deck's
  /// `content_type` stays as it is, even for the last card (BR-67).
  Future<void> deleteCard(String cardId);
}
