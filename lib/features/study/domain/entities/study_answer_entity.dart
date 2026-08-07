import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../deck/domain/models/scheduler_type_model.dart';
import '../models/study_action_model.dart';
import '../models/study_answer_kind_model.dart';
import '../models/study_mode.dart';
import '../models/study_outcome_reason_model.dart';

part 'study_answer_entity.freezed.dart';

/// One recorded turn. Append-only, and kept across every Reset (BR-43).
///
/// **It carries the scheduler and generation it was answered under**, rather
/// than looking them up on the deck. A deck knows only its *current* generation;
/// a history row has to be able to say which cycle and which rules it belonged
/// to, or the history stops meaning anything the first time somebody resets.
@freezed
abstract class StudyAnswerEntity with _$StudyAnswerEntity {
  const factory StudyAnswerEntity({
    required String id,
    required String cardId,
    required String sessionId,

    /// The scheduler at the time of the turn, not the deck's current one.
    required SchedulerType schedulerType,

    /// The generation at the time of the turn.
    required int schedulerGeneration,

    /// What the turn was for (BR-75). Stored, never derived (BR-76).
    required StudyAnswerKind kind,

    /// Which stage produced it (BR-98).
    ///
    /// Never [StudyMode.browse]: that mode grades nothing and writes no row at
    /// all (BR-111).
    required StudyMode mode,

    /// Why it ended, when the action does not say (BR-131). Null when the user
    /// answered of their own accord.
    required StudyOutcomeReason? outcomeReason,

    /// `fill` only: which comparison policy graded it (BR-135).
    ///
    /// Changing the policy bumps the version and must never re-grade older
    /// turns — which is only possible because the version is on the row.
    required int? comparisonVersion,

    /// `fill` only: whether the hint was used (BR-136).
    ///
    /// Recorded, and deliberately without effect on [action] or the schedule.
    required bool? usedHint,

    /// The canonical action — never the label the screen showed (BR-132).
    required StudyAction action,

    required DateTime answeredAt,

    /// The schedule after this turn. Null when the turn moved nothing, which is
    /// every turn of a `learning` session (BR-144).
    required DateTime? nextDueAt,

    required int? previousBox,
    required int? nextBox,
    required double? previousEaseFactor,
    required double? nextEaseFactor,
    required int? previousIntervalDays,
    required int? nextIntervalDays,
  }) = _StudyAnswerEntity;
}
