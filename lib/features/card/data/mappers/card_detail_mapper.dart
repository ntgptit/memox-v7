import '../../../../core/database/app_database.dart';
import '../../domain/models/card_detail_model.dart';
import 'card_mapper.dart';
import 'card_study_state_mapper.dart';

/// Maps the joined detail row to the read model (BR-183).
///
/// **Reuses the two row mappers the list already goes through**, so detail adds
/// no second way to build a card or a study state — which is what keeps the
/// state dot on the row and the state on the detail screen the same fact rather
/// than two computations that agree today.
///
/// The tag delimiter is the ASCII unit separator the query concatenates with
/// (`char(31)`); `TagName.parse` refuses control characters outright, so the
/// split back apart is safe by construction rather than by assumption.
const String _tagSeparator = '\u{1F}';

CardDetailModel cardDetailFromRow(CardDetailByIdResult row) => CardDetailModel(
  card: cardEntityFromRow(row.c),
  studyState: cardStudyStateEntityFromRow(row.s),
  tagNames: _splitTagNames(row.tagNames),
);

List<String> _splitTagNames(String? concatenated) {
  if (concatenated == null || concatenated.isEmpty) return const <String>[];

  return concatenated.split(_tagSeparator);
}
