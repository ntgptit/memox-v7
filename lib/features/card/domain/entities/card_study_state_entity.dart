import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../deck/domain/models/scheduler_type_model.dart';

part 'card_study_state_entity.freezed.dart';

/// The schedule born with a card (BR-09) — the slice of it M4.9 needs to
/// create cards correctly. Review flows extend from here in M5.0, not before.
///
/// Per-scheduler fields are null when they do not belong to [schedulerType]:
/// `eight_box` owns [currentBox]; `sm2` owns [easeFactor], [intervalDays] and
/// [repetitions].
@freezed
abstract class CardStudyStateEntity with _$CardStudyStateEntity {
  const factory CardStudyStateEntity({
    required String cardId,
    required SchedulerType schedulerType,
    required int schedulerVersion,

    /// Must equal the root's current generation (BR-49).
    required int schedulerGeneration,

    /// Null means the card has not finished the learning chain (BR-144), and
    /// it is what `new` means (BR-90). The learning chain writes no `scheduled`
    /// answer at all, so `answerCount` stays 0 through all five stages.
    required DateTime? learnedAt,

    /// Null until the chain completes. Travels with [learnedAt]: never one
    /// without the other (BR-149).
    required DateTime? dueAt,
    required DateTime? lastAnsweredAt,
    required int answerCount,
    required int lapseCount,
    required int? currentBox,
    required double? easeFactor,
    required int? intervalDays,
    required int? repetitions,
  }) = _CardStudyStateEntity;
}
