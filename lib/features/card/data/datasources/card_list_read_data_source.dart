import '../../../../core/database/app_database.dart';
import '../../../../core/error/drift_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/card_entity.dart';
import '../../domain/models/card_list_filter_model.dart';
import '../../domain/models/card_list_item_model.dart';
import '../../domain/models/card_state_distribution_model.dart';
import '../../domain/models/card_state_model.dart';
import 'card_dao.dart';
import '../mappers/card_list_item_mapper.dart';
import '../mappers/card_mapper.dart';

/// The management-list reads, split out of `CardRepositoryImpl` so neither file
/// outgrows the size guard and along a real seam: this is the list surface —
/// the windowed rows and the filter counts (D3, D5) — where the impl's other
/// half is the create/edit/tag/flag writes with their transactions.
///
/// Same boundary as the impl: Drift rows and exceptions stop here, entities and
/// [Failure] leave. It owns its own error mapping rather than borrowing the
/// impl's, so the seam is a clean one.
final class CardListReadDataSource {
  const CardListReadDataSource(this._dao);

  final CardDao _dao;

  Stream<List<CardEntity>> watchCardsByDeck(
    String deckId, {
    required int limit,
  }) {
    _requireWindow(limit);

    return _dao
        .watchCardsByDeck(deckId, limit: limit)
        .handleError(_rethrowMapped)
        .map(
          (List<Card> rows) =>
              rows.map(cardEntityFromRow).toList(growable: false),
        );
  }

  Stream<List<CardListItemModel>> watchCardListItems(
    String deckId, {
    required int limit,
    CardListFilter filter = CardListFilter.all,
    DateTime? now,
  }) {
    _requireWindow(limit);

    // `dueNow` is the only filter that needs `now`, so it insists on it rather
    // than defaulting the clock. Every branch yields the same `CardListItemRow`,
    // so one map covers them all.
    final rows = switch (filter) {
      CardListFilter.all => _dao.watchCardListItemsByDeck(deckId, limit: limit),
      CardListFilter.dueNow => _dao.watchCardListItemsDueByDeck(
        deckId,
        now: _requireNow(now),
        limit: limit,
      ),
      CardListFilter.isNew => _dao.watchCardListItemsNewByDeck(
        deckId,
        limit: limit,
      ),
      CardListFilter.flagged => _dao.watchCardListItemsFlaggedByDeck(
        deckId,
        limit: limit,
      ),
    };

    return rows
        .handleError(_rethrowMapped)
        .map(
          (List<CardListItemRow> list) => list
              .map(
                (CardListItemRow r) => cardListItemFromParts(r.$1, r.$2, r.$3),
              )
              .toList(growable: false),
        );
  }

  Stream<int> watchCardCountByDeck(String deckId) =>
      _dao.watchCardCountByDeck(deckId).handleError(_rethrowMapped);

  Stream<CardStateDistributionModel> watchCardStateDistribution(
    String deckId,
  ) => _dao
      .watchCardStateCounts(
        deckId,
        // The four thresholds live in card_state_model.dart, not the SQL, so
        // changing the ladder is a Dart edit, not a migration (see card.drift).
        reviewingBox: kReviewingBox,
        masteredBox: kMasteredBox,
        reviewingDays: kReviewingIntervalDays,
        masteredDays: kMasteredIntervalDays,
      )
      .handleError(_rethrowMapped)
      .map(
        (r) => CardStateDistributionModel(
          total: r.total,
          isNew: r.newCount ?? 0,
          beginning: r.beginningCount ?? 0,
          reviewing: r.reviewingCount ?? 0,
          mastered: r.masteredCount ?? 0,
        ),
      );

  Stream<int> watchFilteredCardCount(
    String deckId, {
    CardListFilter filter = CardListFilter.all,
    DateTime? now,
  }) => switch (filter) {
    CardListFilter.all => watchCardCountByDeck(deckId),
    CardListFilter.dueNow =>
      _dao
          .watchDueCountByDeck(deckId, now: _requireNow(now))
          .handleError(_rethrowMapped),
    CardListFilter.isNew =>
      _dao.watchNewCountByDeck(deckId).handleError(_rethrowMapped),
    CardListFilter.flagged =>
      _dao.watchFlaggedCountByDeck(deckId).handleError(_rethrowMapped),
  };

  void _requireWindow(int limit) {
    // A window has to be a window. Zero renders an empty deck that has cards;
    // a negative one is SQLite's "no limit", the unbounded read this parameter
    // exists to prevent arriving through the parameter meant to stop it.
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'must be at least 1');
    }
  }

  DateTime _requireNow(DateTime? now) {
    if (now == null) throw ArgumentError.notNull('now');

    return now;
  }

  Never _rethrowMapped(Object error) {
    if (error is Failure) throw error;
    throw mapDatabaseError(error);
  }
}
