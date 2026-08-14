import 'package:drift/drift.dart'
    show Value, BooleanExpressionOperators, InsertMode;
import '../../../../core/database/app_database.dart';
import '../../domain/models/card_list_filter_model.dart';
import '../../domain/models/card_list_sort_model.dart';
import '../../domain/models/tag_filter_model.dart';
import '../mappers/card_list_query_mapper.dart';

/// Data access for the Card side of the vertical.
///
/// Receives the same already-open [AppDatabase] instance as the Card feature's
/// deck-context adapter — one opener (AD-08), one database. Drift transactions
/// are scoped to that database, so `CardRepositoryImpl` can apply BR-09 and
/// BR-62 atomically without importing Deck's data layer.
///
/// This class speaks Drift rows and companions. They stop here: the
/// repository maps them to domain entities and never lets one across (AD-01).
/// One management-list row as it leaves the DAO: the card, its study state and
/// its concatenated tag names. A record, so the repository maps one type.
typedef CardListItemRow = (Card, CardStudyState, String? tagNames);

final class CardDao {
  CardDao(this._db);

  final AppDatabase _db;

  /// Runs [action] atomically — the card + study state + content-type lock
  /// write (BR-09, BR-62) goes through this.
  Future<T> runInTransaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  // ---- reads -------------------------------------------------------------

  /// Newest first, capped at [limit] — see `card.drift` for why both.
  Stream<List<Card>> watchCardsByDeck(String deckId, {required int limit}) =>
      _db.cardsByDeck(deckId, limit).watch();

  /// The management list: one statement, with the filter, the search term and
  /// the sort composed into its `$predicate` and `$order` (see
  /// `card_list_query_mapper.dart` for why this is one query and not four).
  Stream<List<CardListItemRow>> watchCardListItems({
    required String deckId,
    required int limit,
    required CardListFilter filter,
    required CardListSort sort,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  }) {
    final query = _db.cardListItems(
      (c, s) => cardListPredicate(
        db: _db,
        c: c,
        s: s,
        deckId: deckId,
        filter: filter,
        searchTerm: searchTerm,
        now: now,
        tags: tags,
      ),
      (c, s) => cardListOrder(sort, c, s),
      limit,
    );
    List<CardListItemRow> toRows(List<CardListItemsResult> raw) =>
        raw.map((r) => (r.c, r.s, r.tagNames)).toList();

    // **This used to merge a hand-written `tableUpdates` over `tags`/`card_tags`
    // in, and it no longer needs to.** drift once dropped both from this
    // query's generated `readsFrom` — they are read only inside the tag_names
    // subquery — so the watch went silent when a tag was added or removed
    // (IT-ORG-007/008). drift 2.34 walks the subquery: the generated statement
    // now declares `readsFrom: {tags, cardTags, cards, cardStudyStates, …}`,
    // and the tag *filter* (BR-183) rides in through
    // `generatedpredicate.watchedTables` on the same mechanism. Keeping the
    // merge cost a second, identical emission per tag write and left a comment
    // asserting a limitation that had been fixed.
    //
    // `card_list_tag_invalidation_test.dart` and
    // `card_list_tag_filter_test.dart` pin the *behaviour* rather than the
    // mechanism, so they still catch it if drift ever regresses.
    return query.watch().map(toRows);
  }

  /// How many cards the same predicate matches, without the window — so a pill
  /// and the list it opens can never disagree.
  Stream<int> watchCardCount({
    required String deckId,
    required CardListFilter filter,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  }) {
    final query = _db.cardCount(
      (c, s) => cardListPredicate(
        db: _db,
        c: c,
        s: s,
        deckId: deckId,
        filter: filter,
        searchTerm: searchTerm,
        now: now,
        tags: tags,
      ),
    );
    // No hand-written invalidation here either: drift builds this statement's
    // `readsFrom` as `{cards, cardStudyStates, ...generatedpredicate
    // .watchedTables}`, and the tag predicate's `EXISTS` subquery contributes
    // `card_tags` to that set. Untagging the last matching card therefore
    // re-emits on its own — pinned by `card_list_tag_filter_test.dart`, which
    // asserts the count falls to zero on a live stream.
    return query.watchSingle();
  }

  Future<Card?> cardById(String cardId) =>
      _db.cardById(cardId).getSingleOrNull();

  Future<CardStudyState?> studyStateByCard(String cardId) =>
      _db.studyStateByCard(cardId).getSingleOrNull();

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

  Future<void> insertReviewState(CardStudyStatesCompanion state) =>
      _db.into(_db.cardStudyStates).insert(state);

  // ---- flag ---------------------------------------------------------------

  /// Only flagged cards, same window and order as [watchCardsByDeck].
  Stream<List<Card>> watchFlaggedCardsByDeck(
    String deckId, {
    required int limit,
  }) => _db.flaggedCardsByDeck(deckId, limit).watch();

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

  // ---- bulk (BR-165, BR-166, BR-167) --------------------------------------

  /// **SQLite's bind-variable ceiling, honoured once here.** A statement may
  /// carry 999 parameters by default, and an `IN` list of ids spends one each.
  /// Every bulk call below therefore runs in chunks; the caller holds the
  /// transaction open around them, so a chunked write is still one atomic step
  /// (BR-166). 500 leaves room for the statement's own parameters.
  static const int idChunkSize = 500;

  static Iterable<List<String>> _chunks(List<String> ids) sync* {
    for (var start = 0; start < ids.length; start += idChunkSize) {
      final end = start + idChunkSize;
      yield ids.sublist(start, end > ids.length ? ids.length : end);
    }
  }

  /// The ids a predicate matches — Select all, without the window (BR-167).
  Future<List<String>> cardIdsMatching({
    required String deckId,
    required CardListFilter filter,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  }) => _db
      .cardIdsMatching(
        (c, s) => cardListPredicate(
          db: _db,
          c: c,
          s: s,
          deckId: deckId,
          filter: filter,
          searchTerm: searchTerm,
          now: now,
          // The same predicate as the list and the count, tag filter included:
          // a selection built from a different predicate is how a user deletes
          // rows they had filtered away (BR-167, BR-183).
          tags: tags,
        ),
      )
      .get();

  /// Where each card lives and which tree that is, for move validation.
  Future<List<CardDeckContextForIdsResult>> cardDeckContextForIds(
    List<String> cardIds,
  ) async {
    final rows = <CardDeckContextForIdsResult>[];
    for (final chunk in _chunks(cardIds)) {
      rows.addAll(await _db.cardDeckContextForIds(chunk).get());
    }

    return rows;
  }

  Future<void> moveCardsToDeck({
    required List<String> cardIds,
    required String deckId,
    required DateTime updatedAt,
  }) async {
    for (final chunk in _chunks(cardIds)) {
      await _db.moveCardsToDeck(deckId, updatedAt, chunk);
    }
  }

  Future<void> deleteCardsByIds(List<String> cardIds) async {
    for (final chunk in _chunks(cardIds)) {
      await _db.deleteCardsByIds(chunk);
    }
  }

  Future<void> setCardsFlagByIds({
    required List<String> cardIds,
    required bool isFlagged,
    required DateTime updatedAt,
  }) async {
    for (final chunk in _chunks(cardIds)) {
      // `is_flagged` is INTEGER in SQLite; drift hands the column through
      // as `int`, so the boolean is mapped here rather than in three
      // call sites.
      await _db.setCardsFlagByIds(isFlagged ? 1 : 0, updatedAt, chunk);
    }
  }

  /// Card id → how many tags it already carries. Absent means zero.
  Future<Map<String, int>> tagCountsForCards(List<String> cardIds) async {
    final counts = <String, int>{};
    for (final chunk in _chunks(cardIds)) {
      for (final row in await _db.tagCountsForCards(chunk).get()) {
        counts[row.cardId] = row.tagCount;
      }
    }

    return counts;
  }

  /// Which of [cardIds] already carry [tagId] — the idempotent half of a bulk
  /// tag, and the cards that must not be counted against the cap twice.
  Future<Set<String>> cardsAlreadyTagged({
    required String tagId,
    required List<String> cardIds,
  }) async {
    final tagged = <String>{};
    for (final chunk in _chunks(cardIds)) {
      tagged.addAll(await _db.cardsAlreadyTagged(chunk, tagId).get());
    }

    return tagged;
  }

  /// Cards still sitting directly in [deckId] — the count BR-163 reads to
  /// decide whether a source deck kept its content type.
  Future<int> directCardCount(String deckId) =>
      _db.directCardCount(deckId).getSingle();
}
