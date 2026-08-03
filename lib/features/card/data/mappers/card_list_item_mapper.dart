import '../../../../core/database/app_database.dart';
import '../../domain/models/card_list_item_model.dart';
import 'card_mapper.dart';
import 'card_review_state_mapper.dart';

/// Maps a joined `cardListItemsByDeck` row to the list projection.
///
/// Reuses the two existing row mappers — the nested `Card` and `CardReviewState`
/// go through the same `cardEntityFromRow` and `cardReviewStateEntityFromRow` a
/// single-table read uses, so the join adds no second way to build an entity.
/// The delimiter `cardListItemsByDeck` folds tag names with — ASCII unit
/// separator, which a trimmed printable `TagName` can never contain.
const String _tagSeparator = '\u{1F}';

CardListItemModel cardListItemFromRow(CardListItemsByDeckResult row) =>
    CardListItemModel(
      card: cardEntityFromRow(row.c),
      reviewState: cardReviewStateEntityFromRow(row.s),
      tagNames: _splitTagNames(row.tagNames),
    );

List<String> _splitTagNames(String? concatenated) {
  if (concatenated == null || concatenated.isEmpty) return const <String>[];

  return concatenated.split(_tagSeparator);
}
