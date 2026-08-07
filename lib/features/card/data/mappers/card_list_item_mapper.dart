import '../../../../core/database/app_database.dart';
import '../../domain/models/card_list_item_model.dart';
import 'card_mapper.dart';
import 'card_study_state_mapper.dart';

/// Maps the parts of a joined list row to the projection.
///
/// **Takes the parts, not a specific result class**, because the four filter
/// variants (`cardListItemsByDeck` and the Due/New/Flagged ones) each generate
/// their own drift result class, all with the same `.c`, `.s` and `.tagNames`
/// fields. One parts-mapper serves all four; the DAO pulls the three fields off
/// whichever result it read.
///
/// Reuses the two existing row mappers, so the join adds no second way to build
/// an entity. The delimiter is the ASCII unit separator (`char(31)` in the
/// query), which a trimmed printable `TagName` can never contain.
const String _tagSeparator = '\u{1F}';

CardListItemModel cardListItemFromParts(
  Card card,
  CardStudyState studyState,
  String? tagNames,
) => CardListItemModel(
  card: cardEntityFromRow(card),
  studyState: cardStudyStateEntityFromRow(studyState),
  tagNames: _splitTagNames(tagNames),
);

List<String> _splitTagNames(String? concatenated) {
  if (concatenated == null || concatenated.isEmpty) return const <String>[];

  return concatenated.split(_tagSeparator);
}
