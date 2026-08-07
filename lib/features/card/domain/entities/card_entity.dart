import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_entity.freezed.dart';

/// Card content, and only content. No SRS field appears here on purpose: the
/// schedule lives in its own entity so editing a card cannot touch it (BR-10).
///
/// **It validates nothing.** BR-07 and BR-08 belong to `CardText`, whose
/// private constructor makes an invalid side unrepresentable; this entity is
/// what a valid card *is*, read back out of the database. The rule used to live
/// here as a static `validateSide` that threw, and the repository called it
/// again on the way in — two owners of one rule, which is the arrangement
/// `DeckName` was introduced to end on the deck side.
@freezed
abstract class CardEntity with _$CardEntity {
  const factory CardEntity({
    required String id,
    required String deckId,
    required String front,
    required String back,

    /// The user's own mark on this card (BR-92). Content, not schedule — reset
    /// leaves it alone, which is why it sits here beside [front] rather than on
    /// the study-state entity.
    required bool isFlagged,

    /// Optional supporting text (BR-95). `null` means never filled; the domain
    /// folds an empty string to `null` on the way in, so the two are never both
    /// used to mean the same thing.
    required String? example,
    required String? hint,
    required String? pronunciation,

    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CardEntity;

  const CardEntity._();
}
