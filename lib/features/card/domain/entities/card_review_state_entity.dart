import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../deck/domain/models/scheduler_type_model.dart';

part 'card_review_state_entity.freezed.dart';

/// The schedule born with a card (BR-09) — the slice of it M4.9 needs to
/// create cards correctly. Review flows extend from here in M5.0, not before.
///
/// Per-scheduler fields are null when they do not belong to [schedulerType]:
/// `eight_box` owns [currentBox]; `sm2` owns [easeFactor], [intervalDays] and
/// [repetitions].
@freezed
abstract class CardReviewStateEntity with _$CardReviewStateEntity {
  const factory CardReviewStateEntity({
    required String cardId,
    required SchedulerType schedulerType,
    required int schedulerVersion,

    /// Must equal the root's current generation (BR-49).
    required int schedulerGeneration,

    /// Null means due immediately (BR-22). A new card starts null (BR-09).
    required DateTime? dueAt,
    required DateTime? lastReviewedAt,
    required int reviewCount,
    required int lapseCount,
    required int? currentBox,
    required double? easeFactor,
    required int? intervalDays,
    required int? repetitions,
  }) = _CardReviewStateEntity;
}
