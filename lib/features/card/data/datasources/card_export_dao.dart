import '../../../../core/database/app_database.dart';

/// The database surface of one export snapshot (BR-177).
///
/// Its own DAO for the reason `CardImportDao` is one: a whole-deck read whose
/// only job is to feed an encoder is a different job from the windowed,
/// watched reads the card list runs constantly, and the class name says which
/// job a call site is doing.
///
/// **Reads only** (BR-178). There is no write method here, and there is no
/// companion in the signatures — an export that could not touch a row even by
/// mistake is a stronger guarantee than one that promises not to.
///
/// Speaks rows; they stop at the repository (AD-01).
final class CardExportDao {
  CardExportDao(this._db);

  final AppDatabase _db;

  /// The one transaction BR-177 requires. Nothing inside it writes; it is held
  /// open so the deck name and the card rows are read from **one** SQLite
  /// snapshot rather than from two moments a rename can sit between.
  Future<T> runInTransaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  /// The deck's own name, or null when the deck is gone (UC-11 E3).
  Future<String?> deckName(String deckId) =>
      _db.exportDeckName(deckId).getSingleOrNull();

  /// Every card held directly by [deckId], tags included, in BR-177's order.
  Future<List<ExportCardRow>> cardsInDeck(String deckId) =>
      _db.exportCardsInDeck(deckId).get();

  /// How many ids one `IN` clause binds. SQLite's default bind-variable
  /// ceiling is 999 and each id spends one; 400 leaves room for the
  /// statement's own parameters, the same margin `CardImportDao` chose.
  static const int idChunkSize = 400;

  /// Exactly the cards of [deckId] whose id is in [cardIds] — chunked
  /// array-bound statements, never one unbounded `IN` and never one query per
  /// id (BR-177).
  ///
  /// The caller holds the transaction open around the chunks, so every chunk
  /// reads the same snapshot. The rows come back concatenated in chunk order:
  /// each statement is sorted, their concatenation is not, which is why the
  /// repository — where BR-177 puts the ordering contract — sorts the merged
  /// result rather than trusting this list.
  Future<List<ExportCardRow>> cardsByIds({
    required String deckId,
    required List<String> cardIds,
  }) async {
    if (cardIds.isEmpty) return const <ExportCardRow>[];

    final rows = <ExportCardRow>[];
    for (var start = 0; start < cardIds.length; start += idChunkSize) {
      final end = start + idChunkSize;
      rows.addAll(
        await _db
            .exportCardsByIds(
              deckId,
              cardIds.sublist(
                start,
                end > cardIds.length ? cardIds.length : end,
              ),
            )
            .get(),
      );
    }

    return rows;
  }
}
