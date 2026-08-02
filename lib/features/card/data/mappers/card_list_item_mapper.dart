import '../../../../core/database/app_database.dart';
import '../../domain/models/card_list_item_model.dart';
import 'card_mapper.dart';
import 'card_review_state_mapper.dart';

/// Maps a joined `cardListItemsByDeck` row to the list projection.
///
/// Reuses the two existing row mappers — the nested `Card` and `CardReviewState`
/// go through the same `cardEntityFromRow` and `cardReviewStateEntityFromRow` a
/// single-table read uses, so the join adds no second way to build an entity.
CardListItemModel cardListItemFromRow(CardListItemsByDeckResult row) =>
    CardListItemModel(
      card: cardEntityFromRow(row.c),
      reviewState: cardReviewStateEntityFromRow(row.s),
    );
