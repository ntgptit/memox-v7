import 'package:freezed_annotation/freezed_annotation.dart';

part 'study_schedule_model.freezed.dart';

/// A card's schedule as the algorithm sees it — numbers, and nothing else.
///
/// **Not `CardStudyStateEntity`.** That entity belongs to the Card feature and
/// carries ids, stamps and a generation the formulas have no use for. Handing it
/// to a scheduler would mean every matrix test builds a card just to check a
/// piece of integer arithmetic, which is exactly what AD-16 objects to.
///
/// Per-algorithm fields are null when they do not apply: `eight_box` owns [box],
/// `sm2` owns [easeFactor], [intervalDays] and [repetitions].
@freezed
abstract class StudyScheduleModel with _$StudyScheduleModel {
  const factory StudyScheduleModel({
    int? box,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
  }) = _StudyScheduleModel;
}

/// What a scheduler returns: the next schedule, and how many **days** away it
/// is.
///
/// **Days, never an instant** (AD-16). BR-105 anchors the due moment to 00:00
/// local time of the Nth day, and local time is something `domain/` must not
/// know. Returning a `DateTime` here would drag a timezone into the one place
/// that should be pure arithmetic — and would make every 8×2 matrix test build a
/// day boundary to check an integer.
///
/// [StudyDayModel] is the collaborator that turns [intervalDays] into a moment.
@freezed
abstract class StudyScheduleUpdateModel with _$StudyScheduleUpdateModel {
  const factory StudyScheduleUpdateModel({
    required int intervalDays,
    required StudyScheduleModel schedule,
  }) = _StudyScheduleUpdateModel;
}
