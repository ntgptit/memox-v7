import '../../../../core/database/app_database.dart';
import '../../../../core/error/drift_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../domain/failures/card_not_found_failure.dart';
import '../../domain/models/card_detail_model.dart';
import '../../domain/models/card_history_cursor_model.dart';
import '../../domain/models/card_history_page_model.dart';
import '../datasources/card_detail_dao.dart';
import '../mappers/card_detail_mapper.dart';
import '../mappers/card_history_mapper.dart';
import '../../domain/repositories/card_detail_repository.dart';

/// The read side of one card, over Drift (UC-12).
///
/// **It holds a DAO with no write on it, and that is the enforcement of
/// BR-182.** Nothing in this file could mutate the database if it wanted to:
/// there is no transaction, no companion and no clock. A rule stated in prose
/// and a rule you cannot express are not the same guarantee.
///
/// Drift rows and exceptions stop here; domain models and [Failure] leave.
final class CardDetailRepositoryImpl implements CardDetailRepository {
  CardDetailRepositoryImpl(AppDatabase db) : _dao = CardDetailDao(db);

  final CardDetailDao _dao;

  @override
  Stream<CardDetailModel> watchCardDetail(String cardId) => _dao
      .watchCardDetail(cardId)
      .handleError(_rethrowMapped)
      .map(_requireDetail);

  /// A missing row is the card being gone, not an empty result (BR-188).
  ///
  /// The join is total by BR-09 — a card is created with its study state in one
  /// transaction — so "no row" cannot mean "a card without a schedule". It has
  /// exactly one meaning, and the stream says it with the same typed reason the
  /// editor already uses rather than a second one for the same event.
  CardDetailModel _requireDetail(CardDetailByIdResult? row) {
    if (row == null) {
      throw const NotFoundFailure(
        message: 'That card no longer exists.',
        reason: CardNotFoundReason.cardGone,
      );
    }

    return cardDetailFromRow(row);
  }

  @override
  Future<CardHistoryPageModel> loadCardHistoryPage(
    String cardId, {
    CardHistoryCursor? after,
  }) async {
    // One row past the page, so "is there another page" is answered by the read
    // rather than guessed from a short result — a page that comes back exactly
    // full is otherwise indistinguishable from the last page.
    const probe = kCardHistoryPageSize + 1;
    try {
      final rows = after == null
          ? await _dao.historyFirstPage(cardId, limit: probe)
          : await _dao.historyAfter(
              cardId,
              answeredAt: after.answeredAt,
              id: after.id,
              limit: probe,
            );

      return _toPage(rows);
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw mapDatabaseError(error);
    }
  }

  /// The probe row is dropped, never shown: it belongs to the next page, and
  /// keeping it would make the cursor point one row too far and skip it.
  CardHistoryPageModel _toPage(List<StudyAnswer> rows) {
    final hasMore = rows.length > kCardHistoryPageSize;
    final page = hasMore ? rows.sublist(0, kCardHistoryPageSize) : rows;
    final events = page
        .map(cardHistoryEventFromRow)
        .toList(growable: false);

    return CardHistoryPageModel(
      events: events,
      hasMore: hasMore,
      // Null at the end of the history, so `hasMore` and `nextCursor` cannot
      // disagree about whether there is anywhere to resume from.
      nextCursor: hasMore && events.isNotEmpty ? events.last.cursor : null,
    );
  }

  Never _rethrowMapped(Object error) {
    if (error is Failure) throw error;
    throw mapDatabaseError(error);
  }
}
