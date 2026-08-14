import '../../../../core/database/app_database.dart';

/// Data access for the tag catalog (UC-12).
///
/// **Its own adapter beside [CardDao], not three more methods on it.** The two
/// speak to overlapping tables and answer different questions: `CardDao` always
/// starts from a card, and every statement here starts from a tag. Keeping them
/// apart is what lets `TagCatalogRepositoryImpl` show, by the surface it is
/// handed, that a rename cannot reach a `cards` row (BR-188) — a shared adapter
/// carrying `updateCardById` would make that a promise in prose instead.
///
/// Same boundary as its siblings: Drift rows and companions stop here.
final class TagCatalogDao {
  TagCatalogDao(this._db);

  final AppDatabase _db;

  /// Runs [action] atomically — rename/merge and delete both go through this
  /// (BR-186, BR-187).
  Future<T> runInTransaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  // ---- reads -------------------------------------------------------------

  /// Every tag with its card count, narrowed by an **already folded** term
  /// (BR-182). An empty term matches everything.
  ///
  /// The fold happens above this — in the repository, through `TagName`'s own
  /// rule — for the same reason the card search folds in Dart: SQLite's
  /// `lower()` covers ASCII only, so folding here would make `Động từ` and
  /// `động từ` two different searches.
  Stream<List<TagCatalogResult>> watchCatalog({
    required String foldedSearch,
    String? ownerId,
  }) => _db.tagCatalog(ownerId, foldedSearch).watch();

  /// One tag row, read **inside** the transaction that is about to act on it.
  Future<Tag?> tagById(String tagId) => _db.tagById(tagId).getSingleOrNull();

  /// The tag that owns [nameFolded], or null — BR-93's identity test, and the
  /// thing that decides whether a rename is a rename or a merge (BR-186).
  Future<Tag?> tagByFoldedName(String nameFolded, {String? ownerId}) =>
      _db.tagByFoldedName(ownerId, nameFolded).getSingleOrNull();

  /// How many cards carry [tagId].
  Future<int> cardCountForTag(String tagId) =>
      _db.tagCardCount(tagId).getSingle();

  // ---- writes ------------------------------------------------------------

  /// BR-185: the two name columns, on the tag's own row. The id and every
  /// `card_tags` row are untouched.
  Future<int> renameTag({
    required String tagId,
    required String name,
    required String nameFolded,
  }) => _db.renameTagById(name, nameFolded, tagId);

  /// BR-186: give [targetTagId] every card [sourceTagId] has, skipping the
  /// cards that already carry the target. One statement, deduped by the
  /// table's own primary key.
  Future<int> linkCardsOfTagTo({
    required String sourceTagId,
    required String targetTagId,
  }) => _db.linkCardsOfTagTo(targetTagId, sourceTagId);

  /// Every link this tag has (BR-186's second half, BR-187's first half).
  Future<int> unlinkAllCardsFromTag(String tagId) =>
      _db.unlinkAllCardsFromTag(tagId);

  Future<int> deleteTag(String tagId) => _db.deleteTagById(tagId);
}
