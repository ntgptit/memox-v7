import '../../../../core/database/app_database.dart';

/// Data access for the card detail surface (UC-19).
///
/// **Reads only, and there is no write method to leave out later.** BR-239 makes
/// "this screen cannot mutate" a rule; a DAO with no `insert`, `update`,
/// `delete` or `transaction` on it makes the rule structural rather than
/// something a reviewer has to notice.
///
/// Drift rows stop here: the repository maps them to domain models and never
/// lets one across (AD-01).
final class CardDetailDao {
  CardDetailDao(this._db);

  final AppDatabase _db;

  /// The card, its schedule and its tag names, re-emitted on every change.
  ///
  /// **No hand-merged `tableUpdates` here, deliberately.** `watchCardListItems`
  /// carries one because drift used to omit `card_tags`/`tags` from the
  /// `readsFrom` of a query that reads them only inside a correlated subquery.
  /// The generated code for *this* statement lists all four tables, so a merge
  /// would subscribe to the tag tables twice and emit two frames for one tag
  /// edit. `card_detail_repository_test.dart` pins the behaviour that matters —
  /// adding a tag re-emits — rather than the mechanism, so the day drift
  /// changes its mind the test is what says so.
  Stream<CardDetailByIdResult?> watchCardDetail(String cardId) =>
      _db.cardDetailById(cardId).watchSingleOrNull();

  /// The newest [limit] history rows of one card (BR-241).
  Future<List<StudyAnswer>> historyFirstPage(
    String cardId, {
    required int limit,
  }) => _db.cardHistoryFirstPage(cardId, limit).get();

  /// The next [limit] rows strictly after the `(answeredAt, id)` cursor
  /// (BR-241).
  Future<List<StudyAnswer>> historyAfter(
    String cardId, {
    required DateTime answeredAt,
    required String id,
    required int limit,
  }) => _db.cardHistoryAfter(cardId, answeredAt, id, limit).get();
}
