import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';

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
  /// [side] says which field is being checked. Returns the trimmed text. Throws
  /// [ValidationFailure] carrying a typed problem when empty after trim or longer
  /// than [maxSideLength] — never truncates silently.
  ///
  /// Card keeps its rule here for now. Deck moved the equivalent into a
  /// `DeckName` value object so the repository contract could take a validated
  /// value; Card's presentation slice is M4.11 and the same move belongs with it,
  /// not ahead of it.
  static String validateSide(String raw, {required CardSide side}) {
    final text = raw.trim();
    if (text.isEmpty) {
      throw ValidationFailure(
        message: 'The card is invalid: ${side.name} is empty.',
        problems: <Enum>{side.emptyProblem},
      );
    }
    if (text.length > maxSideLength) {
      throw ValidationFailure(
        message: 'The card is invalid: ${side.name} is too long.',
        problems: <Enum>{side.tooLongProblem},
      );
    }

    return text;
  }
}

/// Which side of a card is being validated (BR-07, BR-08).
enum CardSide {
  front,
  back;

  CardValidationProblem get emptyProblem => switch (this) {
    CardSide.front => CardValidationProblem.frontEmpty,
    CardSide.back => CardValidationProblem.backEmpty,
  };

  CardValidationProblem get tooLongProblem => switch (this) {
    CardSide.front => CardValidationProblem.frontTooLong,
    CardSide.back => CardValidationProblem.backTooLong,
  };
}

/// Every way a card form can be wrong — one value per field-and-reason.
/// The same shape as `DeckValidationProblem`: the value names the field as well
/// as the reason, so a screen marks the right input without a separate field key.
enum CardValidationProblem { frontEmpty, frontTooLong, backEmpty, backTooLong }
