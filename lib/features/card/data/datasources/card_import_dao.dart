import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';

/// The database surface of one import commit (BR-171).
///
/// Its own DAO for the same reason `DeckTemplateDao` is one: a batch write of
/// cards, study states, tags and links is a different job from the reads a
/// card list runs constantly, and the class name says which job a call site
/// is doing.
///
/// Speaks rows and companions; they stop at the repository (AD-01).
final class CardImportDao {
  CardImportDao(this._db);

  final AppDatabase _db;

  /// The one transaction BR-171 requires — target checks, duplicate recheck
  /// and every insert run inside it.
  Future<T> runInTransaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  /// The duplicate identities already in [deckId] (BR-170): one statement,
  /// used for the preview read and again for the in-transaction recheck.
  Future<List<CardKeysInDeckResult>> cardKeysInDeck(String deckId) =>
      _db.cardKeysInDeck(deckId).get();

  /// How many folded names one `IN` clause binds. SQLite's default
  /// bind-variable ceiling is 999; 400 leaves room for whatever else a
  /// statement carries, the same margin `CardDao.idChunkSize` chose.
  static const int tagLookupChunkSize = 400;

  /// The tags an import would reuse, by folded identity (BR-93) — chunked
  /// array-bound statements, never one unbounded `IN` and never one query
  /// per tag. Callers run inside the commit transaction, so every chunk
  /// reads the same snapshot; results are deduplicated by folded name in
  /// case a caller's input repeats across chunk borders.
  Future<List<Tag>> tagsByFoldedNames(List<String> foldedNames) async {
    if (foldedNames.isEmpty) return const <Tag>[];

    final byFolded = <String, Tag>{};
    for (
      var start = 0;
      start < foldedNames.length;
      start += tagLookupChunkSize
    ) {
      final chunk = foldedNames.sublist(
        start,
        start + tagLookupChunkSize > foldedNames.length
            ? foldedNames.length
            : start + tagLookupChunkSize,
      );
      for (final tag in await _db.tagsByFoldedNames(chunk).get()) {
        byFolded[tag.nameFolded] = tag;
      }
    }

    return byFolded.values.toList(growable: false);
  }

  /// Every insert of one commit, as a single Drift batch inside the caller's
  /// transaction: each row binds its own statement, so a thousand-card import
  /// is one round trip per table rather than a thousand awaits — and no
  /// statement ever approaches SQLite's bind-variable limit, because rows
  /// bind individually.
  ///
  /// Links use `insertOrIgnore` for the same idempotence the single-card
  /// path has; cards and states insert strictly, because a collision there
  /// is a generated-id bug that must fail the batch (BR-171), not vanish.
  Future<void> insertImportBatch({
    required List<CardsCompanion> cards,
    required List<CardStudyStatesCompanion> states,
    required List<TagsCompanion> tags,
    required List<CardTagsCompanion> links,
  }) => _db.batch((Batch batch) {
    batch
      ..insertAll(_db.cards, cards)
      ..insertAll(_db.cardStudyStates, states)
      ..insertAll(_db.tags, tags)
      ..insertAll(_db.cardTags, links, mode: InsertMode.insertOrIgnore);
  });
}
