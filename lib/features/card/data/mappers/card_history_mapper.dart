import '../../../../core/database/app_database.dart';
import '../../../deck/domain/models/scheduler_type_model.dart';
import '../../../study/domain/models/study_action_model.dart';
import '../../../study/domain/models/study_answer_kind_model.dart';
import '../../../study/domain/models/study_mode.dart';
import '../../../study/domain/models/study_outcome_reason_model.dart';
import '../../domain/models/card_history_event_model.dart';

/// One `study_answers` row as the card's history read model (BR-185).
///
/// **Every field is copied, none is computed.** There is deliberately no
/// `if (previousBox == nextBox)` and no derivation of `kind` from the schedule
/// here: BR-76 stores those columns precisely because the derivation is wrong
/// for a `scheduled` review of a box-8 card, and a mapper that "helpfully"
/// recomputed one would put the bug back at the boundary the rule was written
/// to protect.
///
/// Enums go through their own `fromDbValue`, which is where each one decides
/// whether an unrecognised value degrades or throws — the same rule
/// `study_mapper.dart` states. Repeating that decision here would give one
/// stored value two behaviours depending on which read loaded it.
///
/// `used_hint` is INTEGER because SQLite has no boolean, and it is nullable
/// because it applies to `fill` only — so null stays null rather than becoming
/// `false`, which would claim the hint was offered and declined (BR-136).
CardHistoryEventModel cardHistoryEventFromRow(StudyAnswer row) =>
    CardHistoryEventModel(
      id: row.id,
      answeredAt: row.answeredAt.toUtc(),
      schedulerType: SchedulerType.fromDbValue(row.schedulerType),
      schedulerGeneration: row.schedulerGeneration,
      kind: StudyAnswerKind.fromDbValue(row.kind),
      mode: StudyMode.fromDbValue(row.mode),
      action: StudyAction.fromDbValue(row.action),
      outcomeReason: row.outcomeReason == null
          ? null
          : StudyOutcomeReason.fromDbValue(row.outcomeReason!),
      usedHint: row.usedHint == null ? null : row.usedHint != 0,
      nextDueAt: row.nextDueAt?.toUtc(),
      previousBox: row.previousBox,
      nextBox: row.nextBox,
      previousEaseFactor: row.previousEaseFactor,
      nextEaseFactor: row.nextEaseFactor,
      previousIntervalDays: row.previousIntervalDays,
      nextIntervalDays: row.nextIntervalDays,
    );
