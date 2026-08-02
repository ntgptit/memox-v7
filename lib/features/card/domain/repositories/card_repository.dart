import '../entities/card_entity.dart';
import '../models/card_text_model.dart';

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
  /// One deck's cards, newest first, capped at [limit] — re-emitted on every
  /// change (AD-01).
  ///
  /// **[limit] is a window, not a page number.** The caller asks for the first
  /// N and asks again for a larger N as the reader scrolls; there is no cursor
  /// and no offset, so the window is always re-read whole and an insert above
  /// it can neither duplicate a row nor drop one. How the window grows is the
  /// screen's business — this layer has no concept of a page.
  ///
  /// Newest first because a just-created card must be visible without scrolling
  /// (UC-04 A4). This is a management order and decides nothing about study:
  /// the review queue is ordered by BR-23 through its own query.
  Stream<List<CardEntity>> watchCardsByDeck(
    String deckId, {
    required int limit,
  });

  /// How many cards the deck holds, whatever the window is showing.
  ///
  /// **A second read rather than a field on the one above**, because the count
  /// has to come from its own statement: a window function computing it beside
  /// the rows would make SQLite materialise the whole deck and cancel the early
  /// stop the `LIMIT` exists for.
  ///
  /// AD-13 asks for one read where two facts jointly decide something — the
  /// deck screen's action set was computed from two snapshots and rendered the
  /// wrong buttons. These two decide nothing together: the count is a label
  /// beside the list, so a frame where it trails the rows by one is a stale
  /// label, not a wrong control.
  Stream<int> watchCardCountByDeck(String deckId);

  /// Creates a card and exactly one review state atomically — BR-09, BR-62.
  /// The state carries the root's scheduler, version and current generation,
  /// `due_at = NULL`, and the scheduler's initial values; a deck still
  /// `unset` becomes `card` in the same atomic step.
  ///
  /// [front] and [back] are [CardText], not `String`: BR-07 and BR-08 have been
  /// applied before the call, and the signature is what says so.
  Future<CardEntity> createCard({
    required String deckId,
    required CardText front,
    required CardText back,
  });

  /// Updates card content only (BR-10) — the review state and history are
  /// untouched, structurally, because this writes only to `cards`.
  Future<CardEntity> updateCard({
    required String cardId,
    required CardText front,
    required CardText back,
  });

  /// Deletes a card; its review state and history cascade. The deck's
  /// `content_type` stays as it is, even for the last card (BR-67).
  Future<void> deleteCard(String cardId);
}
