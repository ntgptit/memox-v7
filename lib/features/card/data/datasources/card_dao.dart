import 'package:drift/drift.dart'
    show Value, BooleanExpressionOperators, InsertMode;
import '../../../../core/database/app_database.dart';

/// Data access for the Card side of the vertical.
///
/// Receives the same already-open [AppDatabase] instance as the Card feature's
/// deck-context adapter — one opener (AD-08), one database. Drift transactions
/// are scoped to that database, so `CardRepositoryImpl` can apply BR-09 and
/// BR-62 atomically without importing Deck's data layer.
///
/// This class speaks Drift rows and companions. They stop here: the
/// repository maps them to domain entities and never lets one across (AD-01).
/// One management-list row as it leaves the DAO: the card, its review state and
/// its concatenated tag names. A record so all four filter queries — each with
/// its own drift result class — share one type the repository maps once.
typedef CardListItemRow = (Card, CardReviewState, String? tagNames);

final class CardDao {
  CardDao(this._db);

  final AppDatabase _db;

  /// Runs [action] atomically — the card + review state + content-type lock
  /// write (BR-09, BR-62) goes through this.
  Future<T> runInTransaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  // ---- reads -------------------------------------------------------------

  /// Newest first, capped at [limit] — see `card.drift` for why both.
  Stream<List<Card>> watchCardsByDeck(String deckId, {required int limit}) =>
      _db.cardsByDeck(deckId, limit).watch();

  /// The window joined to each card's review state and tags (see `card.drift`).
  ///
  /// **Every filter yields the same record type** — `(Card, CardReviewState,
  /// String? tagNames)` — even though drift generates a distinct result class per
  /// query, so the repository maps all four through one path without a per-filter
  /// branch. The tuple carries Drift rows, not domain entities: they still stop
  /// at the repository (AD-01).
  Stream<List<CardListItemRow>> watchCardListItemsByDeck(
    String deckId, {
    required int limit,
  }) => _db
      .cardListItemsByDeck(deckId, limit)
      .watch()
      .map((rows) => rows.map((r) => (r.c, r.s, r.tagNames)).toList());

  /// The same read, filtered to cards due now (BR-22).
  Stream<List<CardListItemRow>> watchCardListItemsDueByDeck(
    String deckId, {
    required DateTime now,
    required int limit,
  }) => _db
      .cardListItemsDueByDeck(deckId, now, limit)
      .watch()
      .map((rows) => rows.map((r) => (r.c, r.s, r.tagNames)).toList());

  /// The same read, filtered to new cards — no scheduled review yet (BR-90).
  Stream<List<CardListItemRow>> watchCardListItemsNewByDeck(
    String deckId, {
    required int limit,
  }) => _db
      .cardListItemsNewByDeck(deckId, limit)
      .watch()
      .map((rows) => rows.map((r) => (r.c, r.s, r.tagNames)).toList());

  /// The same read, filtered to flagged cards (BR-92).
  Stream<List<CardListItemRow>> watchCardListItemsFlaggedByDeck(
    String deckId, {
    required int limit,
  }) => _db
      .cardListItemsFlaggedByDeck(deckId, limit)
      .watch()
      .map((rows) => rows.map((r) => (r.c, r.s, r.tagNames)).toList());

  /// The deck's whole card count, for the "showing N of M" line.
  Stream<int> watchCardCountByDeck(String deckId) =>
      _db.cardCountByDeck(deckId).watchSingle();

  /// The Due-now pill count (BR-22).
  Stream<int> watchDueCountByDeck(String deckId, {required DateTime now}) =>
      _db.dueCountByDeck(deckId, now).watchSingle();

  /// The New pill count (BR-90).
  Stream<int> watchNewCountByDeck(String deckId) =>
      _db.newCountByDeck(deckId).watchSingle();

  Future<Card?> cardById(String cardId) =>
      _db.cardById(cardId).getSingleOrNull();

  Future<CardReviewState?> reviewStateByCard(String cardId) =>
      _db.reviewStateByCard(cardId).getSingleOrNull();

  // ---- writes ------------------------------------------------------------

  Future<void> insertCard(CardsCompanion card) =>
      _db.into(_db.cards).insert(card);

  Future<int> updateCardById(String cardId, CardsCompanion changes) =>
      (_db.update(
        _db.cards,
      )..where((Cards card) => card.id.equals(cardId))).write(changes);

  Future<int> deleteCardById(String cardId) => (_db.delete(
    _db.cards,
  )..where((Cards card) => card.id.equals(cardId))).go();

  Future<void> insertReviewState(CardReviewStatesCompanion state) =>
      _db.into(_db.cardReviewStates).insert(state);

  // ---- flag ---------------------------------------------------------------

  /// Only flagged cards, same window and order as [watchCardsByDeck].
  Stream<List<Card>> watchFlaggedCardsByDeck(
    String deckId, {
    required int limit,
  }) => _db.flaggedCardsByDeck(deckId, limit).watch();

  Stream<int> watchFlaggedCountByDeck(String deckId) =>
      _db.flaggedCountByDeck(deckId).watchSingle();

  /// Writes only the flag. A `CardsCompanion` covering the whole row would let a
  /// caller change `front` while meaning to toggle a mark — and BR-92 is about
  /// the flag being content the *user* owns, not something an edit path moves.
  Future<int> setCardFlag(String cardId, {required bool isFlagged}) =>
      (_db.update(_db.cards)..where((Cards card) => card.id.equals(cardId)))
          .write(CardsCompanion(isFlagged: Value(isFlagged ? 1 : 0)));

  /// One card's flag as a stream, so the editor's toggle reflects a write
  /// without re-reading the whole card. Re-emits on every change to the row.
  Stream<bool> watchCardFlag(String cardId) => _db
      .cardById(cardId)
      .watchSingleOrNull()
      .map((Card? row) => row?.isFlagged == 1);

  // ---- state counts -------------------------------------------------------

  /// The four numbers behind the deck progress panel.
  ///
  /// Thresholds are passed in rather than written into the SQL — see
  /// `card.drift`, and `card_state_model.dart` for where they live.
  Stream<CardStateCountsByDeckResult> watchCardStateCounts(
    String deckId, {
    required int reviewingBox,
    required int masteredBox,
    required int reviewingDays,
    required int masteredDays,
  }) => _db
      .cardStateCountsByDeck(
        reviewingBox,
        reviewingDays,
        masteredBox,
        masteredDays,
        deckId,
      )
      .watchSingle();

  // ---- tags ---------------------------------------------------------------

  Stream<List<Tag>> watchAllTags({String? ownerId}) =>
      _db.allTags(ownerId).watch();

  Stream<List<Tag>> watchTagsForCard(String cardId) =>
      _db.tagsForCard(cardId).watch();

  /// Tags for a whole window of cards in one statement — see `tag.drift` for
  /// why this exists rather than a call per row.
  Stream<List<TagsForCardsResult>> watchTagsForCards(List<String> cardIds) =>
      _db.tagsForCards(cardIds).watch();

  Future<Tag?> tagByFoldedName(String nameFolded, {String? ownerId}) =>
      _db.tagByFoldedName(ownerId, nameFolded).getSingleOrNull();

  Future<int> tagCountForCard(String cardId) =>
      _db.tagCountForCard(cardId).getSingle();

  Future<void> insertTag(TagsCompanion tag) => _db.into(_db.tags).insert(tag);

  /// Links a tag to a card, idempotently. `insertOrIgnore` because the pair is
  /// the primary key (BR-94's table): adding a tag a card already carries is a
  /// no-op, not a constraint error the repository would have to map back.
  Future<void> linkTag(String cardId, String tagId) => _db
      .into(_db.cardTags)
      .insert(
        CardTagsCompanion.insert(cardId: cardId, tagId: tagId),
        mode: InsertMode.insertOrIgnore,
      );

  Future<int> unlinkTag(String cardId, String tagId) =>
      (_db.delete(_db.cardTags)..where(
            (CardTags link) =>
                link.cardId.equals(cardId) & link.tagId.equals(tagId),
          ))
          .go();
}
