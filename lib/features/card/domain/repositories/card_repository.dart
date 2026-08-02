import '../entities/card_entity.dart';
import '../entities/tag_entity.dart';
import '../failures/tag_validation_failure.dart';
import '../models/card_list_item_model.dart';
import '../models/card_text_model.dart';
import '../models/tag_name_model.dart';

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

  /// The same window as [watchCardsByDeck], each card joined to its review state
  /// so a row can show its state dot and label (D5, BR-89…BR-91).
  ///
  /// A richer read than [watchCardsByDeck], not a replacement: the editor prefill
  /// and the create flow want a bare [CardEntity], while the list wants the pair.
  /// Both are one statement — this one joins, because the row needs the card and
  /// its state in the same frame (AD-13), and the join is total by BR-09 (every
  /// card is born with exactly one state).
  Stream<List<CardListItemModel>> watchCardListItems(
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

  /// One card by id, for the editor to prefill.
  ///
  /// A one-shot read, not a stream: the editor takes a snapshot when it opens
  /// and the user edits that. A card deleted from another screen while the form
  /// is open surfaces as a `NotFoundFailure` on save, which is where it matters —
  /// re-fetching live would only let the form's text fight an incoming change.
  Future<CardEntity> getCard(String cardId);

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

  /// Sets the user's flag on a card (BR-92).
  ///
  /// Writes only `is_flagged`, never the schedule or the rest of the content:
  /// the flag is a mark the user owns, and toggling it is not an edit. Idempotent
  /// — setting the value it already holds is a no-op, so a double tap cannot
  /// desync the mark from what the row shows.
  Future<void> setCardFlag({required String cardId, required bool isFlagged});

  /// One card's flag as a stream (BR-92), so the editor's toggle shows the
  /// current mark and reflects its own write without re-reading the card.
  Stream<bool> watchCardFlag(String cardId);

  /// One card's tags, re-emitted on every change (BR-93).
  ///
  /// A stream, not a one-shot: the editor's chip strip must reflect an add or a
  /// remove without a reload, and the same watch drives the row's chips.
  Stream<List<TagEntity>> watchCardTags(String cardId);

  /// Attaches a tag to a card, creating the tag if no one owns its name yet
  /// (BR-93, BR-94).
  ///
  /// [name] is a [TagName], so BR-93's trim and length are already applied — the
  /// signature says so. Case-insensitive reuse is deliberate: adding `noun` when
  /// `Noun` exists attaches the existing tag rather than minting a duplicate, so
  /// a later filter by `noun` finds both cards.
  ///
  /// **The ten-tag cap (BR-94) is checked inside the write**, not above it: the
  /// count and the link have to be one atomic step, or two adds racing each other
  /// both pass an eleventh tag. Over the cap surfaces as a `ValidationFailure`
  /// carrying [TagValidationProblem.tooManyTags]. Adding a tag the card already
  /// has is a no-op.
  Future<void> addCardTag({required String cardId, required TagName name});

  /// Detaches a tag from a card (BR-93). The tag row itself stays — another card
  /// may still carry it, and an orphaned tag harms nothing.
  Future<void> removeCardTag({required String cardId, required String tagId});
}
