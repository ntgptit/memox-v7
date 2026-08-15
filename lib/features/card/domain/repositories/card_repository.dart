import '../entities/card_entity.dart';
import '../entities/tag_entity.dart';
import '../failures/tag_validation_failure.dart';
import '../models/card_list_filter_model.dart';
import '../models/card_list_item_model.dart';
import '../models/card_list_sort_model.dart';
import '../models/card_move_target_model.dart';
import '../models/card_state_distribution_model.dart';
import '../models/card_text_model.dart';
import '../models/deck_context_model.dart';
import '../models/tag_filter_model.dart';
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
  /// the study queue is ordered by BR-23 through its own query.
  Stream<List<CardEntity>> watchCardsByDeck(
    String deckId, {
    required int limit,
  });

  /// The same window as [watchCardsByDeck], each card joined to its study state
  /// and tags so a row can show its state dot, label and chips (D5, BR-89…BR-91,
  /// BR-93), narrowed by [filter] (D3).
  ///
  /// [filter] adds one indexed `WHERE` and nothing else — the order and the
  /// window contract hold across all four (C1, C2). [now] is only read by
  /// [CardListFilter.due]; the caller passes the composition-root clock so no
  /// widget touches the wall clock.
  ///
  /// [tags] narrows further, by OR **within** the selected tags and AND with
  /// everything above (BR-231). [TagFilter.none] applies no tag predicate at
  /// all, so this read is unchanged for every caller that does not filter by
  /// tag. A card carrying three of the selected tags still occupies exactly one
  /// row of the window — the predicate is an existence test, not a join.
  Stream<List<CardListItemModel>> watchCardListItems(
    String deckId, {
    required int limit,
    CardListFilter filter = CardListFilter.all,
    CardListSort sort = CardListSort.newest,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  });

  /// How many cards a [filter] would show — the "showing N of M" denominator and
  /// the pill counts (D3). Its own statement per filter, like the reads.
  ///
  /// Takes [tags] for the same reason it takes [searchTerm]: the count and the
  /// list must be the same predicate, or the header says "Showing 12 of 3"
  /// (BR-231).
  Stream<int> watchFilteredCardCount(
    String deckId, {
    CardListFilter filter = CardListFilter.all,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  });

  /// The deck's four-state distribution, for the progress panel (D5, BR-88…91).
  /// One aggregate over every card, not a count of the window.
  Stream<CardStateDistributionModel> watchCardStateDistribution(String deckId);

  /// The card list's header: the deck's own name and the path of ancestors above
  /// it (W1), re-emitted so a rename lands on the title and the breadcrumb in one
  /// frame (AD-13).
  ///
  /// A card-side read of deck rows, not a call into the deck feature — the same
  /// seam `createCard` already uses. The returned [DeckContextModel] carries no
  /// Drift type; the ancestry is decoded from a JSON scalar at the boundary.
  Stream<DeckContextModel> watchDeckContext(String deckId);

  /// Whether the deck holds cards (BR-63) — the one fact the router's auto-forward
  /// redirect needs, read once rather than watched.
  ///
  /// A lean one-shot: it reads the deck's `content_type`, not the ancestry the
  /// header needs, because a redirect that runs before every deck opens must not
  /// pay for a breadcrumb it will not show. Returns `false` for a missing deck —
  /// there is nothing to forward into.
  Future<bool> readDeckHoldsCards(String deckId);

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

  /// Creates a card and exactly one study state atomically — BR-09, BR-62.
  /// The state carries the root's scheduler, version and current generation,
  /// `due_at = NULL`, and the scheduler's initial values; a deck still
  /// `unset` becomes `card` in the same atomic step.
  ///
  /// [front] and [back] are [CardText], not `String`: BR-07 and BR-08 have been
  /// applied before the call, and the signature is what says so. The three
  /// details are [CardDetailText] and optional (BR-95) — null means the column
  /// is left empty.
  Future<CardEntity> createCard({
    required String deckId,
    required CardText front,
    required CardText back,
    CardDetailText? example,
    CardDetailText? hint,
    CardDetailText? pronunciation,
  });

  /// One card by id, for the editor to prefill.
  ///
  /// A one-shot read, not a stream: the editor takes a snapshot when it opens
  /// and the user edits that. A card deleted from another screen while the form
  /// is open surfaces as a `NotFoundFailure` on save, which is where it matters —
  /// re-fetching live would only let the form's text fight an incoming change.
  Future<CardEntity> getCard(String cardId);

  /// Updates card content only (BR-10) — the study state and history are
  /// untouched, structurally, because this writes only to `cards`. The three
  /// details are rewritten too (BR-95); a null clears the column, so editing a
  /// detail to empty removes it.
  Future<CardEntity> updateCard({
    required String cardId,
    required CardText front,
    required CardText back,
    CardDetailText? example,
    CardDetailText? hint,
    CardDetailText? pronunciation,
  });

  /// Deletes a card; its study state and history cascade. Deleting the last
  /// card returns the deck to `unset` in the same write — BR-163 makes the type
  /// system state, not a setting.
  Future<void> deleteCard(String cardId);

  /// Moves [cardIds] into [targetDeckId] — one transaction, all or nothing
  /// (BR-165, BR-166).
  ///
  /// **The one primitive both callers use.** Moving a single card passes a
  /// one-element list; there is no second transaction path to keep in step.
  /// Only `deck_id` and `updated_at` are written: id, both faces, the three
  /// details, study state, review history, flag, tags and `created_at` all
  /// survive the move untouched.
  ///
  /// Refuses — without writing anything — a target that is the source deck,
  /// a root, a deck holding sub-decks, or a deck in another tree. Both ends of
  /// the move keep their content type honest in the same transaction: an
  /// emptied source goes back to `unset`, an `unset` target becomes `card`
  /// (BR-163).
  Future<void> moveCards({
    required List<String> cardIds,
    required String targetDeckId,
  });

  /// Deletes [cardIds] with their study state and history — one transaction
  /// (BR-166). A deck left empty goes back to `unset` (BR-163).
  Future<void> deleteCards(List<String> cardIds);

  /// Sets the flag on [cardIds] to [isFlagged] (BR-92, BR-166).
  ///
  /// **Explicit, never a toggle.** A batch toggle derived from the first card
  /// flips a mixed selection into another mixed selection, which is not an
  /// outcome any user asked for.
  Future<void> setCardsFlag({
    required List<String> cardIds,
    required bool isFlagged,
  });

  /// Adds one tag to every card in [cardIds] (BR-93, BR-94, BR-166).
  ///
  /// Reuses the tag that owns the folded name, is a no-op for a card that
  /// already carries it, and refuses the **whole** batch if any card would
  /// pass ten tags.
  Future<void> addTagToCards({
    required List<String> cardIds,
    required TagName name,
  });

  /// The decks [sourceDeckId]'s cards may move into (BR-165, UC-04 A5).
  ///
  /// Watched rather than read once: the picker stays open while the tree can
  /// change under it, and a deck that stops being a legal target should leave
  /// the list rather than be refused after the tap.
  ///
  /// Every row is legal by construction — same root, not a root, not holding
  /// sub-decks, not the source — so the picker renders the list and does not
  /// re-derive the rule.
  Stream<List<CardMoveTarget>> watchMoveTargets(String sourceDeckId);

  /// The ids a deck's list currently matches, under the same filter and search
  /// term the screen is showing (BR-167).
  ///
  /// For Select all. Ids only: the selection is a set of strings, and carrying
  /// every front and back across the isolate boundary to build it is the cost
  /// this exists to avoid.
  Future<List<String>> readCardIdsMatching(
    String deckId, {
    CardListFilter filter = CardListFilter.all,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  });

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
