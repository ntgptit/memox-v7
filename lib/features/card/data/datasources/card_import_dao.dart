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

  /// The tags an import would reuse, by folded identity (BR-93) — one
  /// array-bound statement for the batch's whole distinct-tag set.
  Future<List<Tag>> tagsByFoldedNames(List<String> foldedNames) =>
      foldedNames.isEmpty
      ? Future<List<Tag>>.value(const <Tag>[])
      : _db.tagsByFoldedNames(foldedNames).get();

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
