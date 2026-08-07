import 'dart:async';

import 'package:drift/drift.dart'
    show
        Value,
        BooleanExpressionOperators,
        InsertMode,
        TableUpdate,
        TableUpdateQuery;
import '../../../../core/database/app_database.dart';
import '../../domain/models/card_list_filter_model.dart';
import '../../domain/models/card_list_sort_model.dart';
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
  }) {
    final query = _db.cardListItems(
      (c, s) => cardListPredicate(
        c: c,
        s: s,
        deckId: deckId,
        filter: filter,
        searchTerm: searchTerm,
        now: now,
      ),
      (c, s) => cardListOrder(sort, c, s),
      limit,
    );
    List<CardListItemRow> toRows(List<CardListItemsResult> raw) =>
        raw.map((r) => (r.c, r.s, r.tagNames)).toList();

    // drift 2.34's analyzer drops `card_tags`/`tags` from this query's
    // generated `readsFrom` — they are read only inside the tag_names
    // subquery — so the plain watch never re-emits when a tag is added or
    // removed (IT-ORG-007/008). This merge completes the dependency set by
    // hand: the base watch covers `cards`/`card_study_states`, and a write
    // to either tag table triggers a re-read of the same query.
    // `card_list_tag_invalidation_test.dart` pins the behaviour.
    return Stream<List<CardListItemRow>>.multi((listener) {
      final subscriptions = <StreamSubscription<Object?>>[
        query
            .watch()
            .map(toRows)
            .listen(listener.add, onError: listener.addError),
        _db
            .tableUpdates(
              TableUpdateQuery.onAllTables([_db.cardTags, _db.tags]),
            )
            .listen(
              (Set<TableUpdate> _) => query
                  .get()
                  .then((raw) => listener.add(toRows(raw)))
                  .catchError(listener.addError),
              onError: listener.addError,
            ),
      ];
      listener.onCancel = () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      };
    });
  }

  /// How many cards the same predicate matches, without the window — so a pill
  /// and the list it opens can never disagree.
  Stream<int> watchCardCount({
    required String deckId,
    required CardListFilter filter,
    String? searchTerm,
    DateTime? now,
  }) => _db
      .cardCount(
        (c, s) => cardListPredicate(
          c: c,
          s: s,
          deckId: deckId,
          filter: filter,
          searchTerm: searchTerm,
          now: now,
        ),
      )
      .watchSingle();

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
}
