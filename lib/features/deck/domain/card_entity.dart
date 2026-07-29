import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/failure.dart';

part 'card_entity.freezed.dart';

/// Card content, and only content. No SRS field appears here on purpose: the
/// schedule lives in its own entity so editing a card cannot touch it (BR-10).
@freezed
abstract class CardEntity with _$CardEntity {
  const factory CardEntity({
    required String id,
    required String deckId,
    required String front,
    required String back,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CardEntity;

  const CardEntity._();

  /// Longest allowed side after trimming (BR-08).
  static const int maxSideLength = 2000;

  /// Validates and normalises one side of a card (BR-07, BR-08).
  ///
  /// [side] names the field for the error ('front' or 'back'). Returns the
  /// trimmed text. Throws [ValidationFailure] when empty after trim or longer
  /// than [maxSideLength] — never truncates silently.
  static String validateSide(String raw, {required String side}) {
    final text = raw.trim();
    if (text.isEmpty) {
      throw ValidationFailure(
        message: 'Please check the highlighted fields.',
        fieldErrors: <String, String>{side: 'This side must not be empty.'},
      );
    }
    if (text.length > maxSideLength) {
      throw ValidationFailure(
        // Not const: `side` is a runtime value.
        message: 'Please check the highlighted fields.',
        fieldErrors: <String, String>{
          side: 'Content is longer than $maxSideLength characters.',
        },
      );
    }

    return text;
  }
}
