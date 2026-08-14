import '../../../../core/database/app_database.dart';
import '../../../../core/error/drift_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../domain/failures/tag_catalog_failure.dart';
import '../../domain/models/tag_catalog_entry_model.dart';
import '../../domain/models/tag_name_model.dart';
import '../../domain/repositories/tag_catalog_repository.dart';
import '../datasources/tag_catalog_dao.dart';
import '../mappers/tag_catalog_mapper.dart';

/// Drift-backed [TagCatalogRepository] (UC-12).
///
/// **It is handed the database and builds its own adapter**, the same shape
/// `CardRepositoryImpl` uses and for the same reason: a rename that turns into
/// a merge is four writes plus the read that decides between them, and they
/// have to share one transaction. Two ready-made adapters would let the
/// composition root hand it instances from two databases, which would put the
/// collision test outside the rollback.
///
/// **Its whole surface writes exactly two tables.** There is no path from here
/// to a `cards` row, and that is BR-188 made structural rather than promised —
/// `TagCatalogDao` has no card statement to call.
///
/// Below this line, Drift rows and exceptions; above it, domain models and
/// [Failure].
final class TagCatalogRepositoryImpl implements TagCatalogRepository {
  TagCatalogRepositoryImpl(AppDatabase database)
    : _dao = TagCatalogDao(database);

  final TagCatalogDao _dao;

  @override
  Stream<List<TagCatalogEntry>> watchTagCatalog({String? searchTerm}) => _dao
      .watchCatalog(foldedSearch: _foldSearch(searchTerm))
      .handleError(_rethrowMapped)
      .map(
        (List<TagCatalogResult> rows) =>
            rows.map(tagCatalogEntryFromRow).toList(growable: false),
      );

  @override
  Future<TagRenameOutcome> renameTag({
    required String tagId,
    required TagName name,
  }) => _guard(
    () => _dao.runInTransaction(() async {
      // Read inside the transaction: the row this acts on has to be the row
      // that exists at the moment of the write, not the one the catalog
      // rendered a second ago.
      final source = await _dao.tagById(tagId);
      if (source == null) _refuseMissingTag();

      final owner = await _dao.tagByFoldedName(name.folded);

      // The folded name is free, or is this tag's own — `noun` → `Noun` keeps
      // the same identity, so it is a re-spelling and not a merge (BR-185).
      if (owner == null || owner.id == tagId) {
        await _dao.renameTag(
          tagId: tagId,
          name: name.value,
          nameFolded: name.folded,
        );

        return TagRenameOutcome.renamed;
      }

      await _mergeInto(sourceTagId: tagId, targetTagId: owner.id);

      return TagRenameOutcome.merged;
    }),
  );

  @override
  Future<void> deleteTag(String tagId) => _guard(
    () => _dao.runInTransaction(() async {
      final tag = await _dao.tagById(tagId);
      if (tag == null) _refuseMissingTag();

      // **Unlink, then delete the tag — never the other way round, and never
      // by relying on the cascade** (BR-187). Cards are not touched at all:
      // this removes rows from the join table, so a card that carried only
      // this tag keeps its content, its flag, its schedule and its history.
      await _dao.unlinkAllCardsFromTag(tagId);
      await _dao.deleteTag(tagId);
    }),
  );

  /// BR-186's merge, inside a transaction the caller already opened.
  ///
  /// Three statements, in this order and no other:
  ///
  /// 1. give the target every card the source has and the target does not —
  ///    `INSERT OR IGNORE` deduplicates against the target's own primary key,
  ///    so a card carrying both tags is skipped rather than read first;
  /// 2. drop every remaining link of the source, which is now exactly the set
  ///    that was skipped;
  /// 3. delete the source row.
  ///
  /// **No card's tag count can rise.** A card that had the source and not the
  /// target trades one for one at step 1 and 2; a card that had both loses one
  /// at step 2; a card that had only the target is untouched. So BR-94's cap
  /// needs no check here — it cannot be crossed by this operation, which is a
  /// stronger statement than checking it would be. `tag_catalog_merge_test`
  /// pins that with a card already holding ten tags.
  Future<void> _mergeInto({
    required String sourceTagId,
    required String targetTagId,
  }) async {
    await _dao.linkCardsOfTagTo(
      sourceTagId: sourceTagId,
      targetTagId: targetTagId,
    );
    await _dao.unlinkAllCardsFromTag(sourceTagId);
    await _dao.deleteTag(sourceTagId);
  }

  /// The catalog's search term, folded by **BR-93's own rule**.
  ///
  /// `TagName.fold` rather than a bare `toLowerCase()`: the stored
  /// `name_folded` column was written by `TagName`, so anything else here would
  /// be a second folding rule on the other side of one comparison — the exact
  /// defect `searchPredicate` had to be repaired out of.
  ///
  /// **Folded, not parsed.** A search term is not a name being created: it may
  /// be longer than BR-93's fifty characters, and refusing it would turn "I
  /// typed too much" into "no filter", which shows more rows rather than fewer.
  /// A blank term folds to the empty string, which the statement reads as "no
  /// search".
  static String _foldSearch(String? searchTerm) =>
      searchTerm == null ? '' : TagName.fold(searchTerm);

  Never _refuseMissingTag() => throw const NotFoundFailure(
    message: 'That tag no longer exists.',
    reason: TagCatalogProblem.tagMissing,
  );

  /// Maps Drift/SQLite exceptions to [Failure], letting a [Failure] the body
  /// already threw pass through untouched — the shape `CardRepositoryImpl`
  /// uses, so a refusal is not re-wrapped as a database error.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw mapDatabaseError(error);
    }
  }

  Never _rethrowMapped(Object error) {
    if (error is Failure) throw error;
    throw mapDatabaseError(error);
  }
}
