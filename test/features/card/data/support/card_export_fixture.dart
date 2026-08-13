import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_record_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';

/// Builds a canonical record the way production does — through `CardText`,
/// `CardDetailText` and `TagName`.
///
/// Not a shortcut around the value objects: a fixture that constructed records
/// from raw strings could encode text no card can hold, and the encoder tests
/// would then be exercising input the repository can never hand them.
CardTransferRecord exportRecord({
  required String front,
  required String back,
  String? example,
  String? hint,
  String? pronunciation,
  List<String> tags = const <String>[],
}) {
  final sides = parseCardSides(rawFront: front, rawBack: back);

  return CardTransferRecord(
    front: sides.front,
    back: sides.back,
    example: _detail(example, CardDetailField.example),
    hint: _detail(hint, CardDetailField.hint),
    pronunciation: _detail(pronunciation, CardDetailField.pronunciation),
    tags: <TagName>[for (final tag in tags) _tag(tag)],
  );
}

CardDetailText? _detail(String? raw, CardDetailField field) {
  if (raw == null) return null;
  final parsed = CardDetailText.parse(raw, field: field);
  final problem = parsed.problem;
  if (problem != null) {
    throw ArgumentError('fixture detail is invalid: $problem');
  }

  return parsed.text;
}

TagName _tag(String raw) {
  final parsed = TagName.parse(raw);
  final name = parsed.name;
  if (name == null) {
    throw ArgumentError('fixture tag is invalid: ${parsed.problem}');
  }

  return name;
}
