import '../../../../core/database/app_database.dart';
import '../../../../core/time/local_day_model.dart';
import '../../domain/models/reminder_workload_model.dart';

/// One workload row, turned into the model BR-223 can rank.
///
/// **The calendar arithmetic happens here, not in SQL and not in the use case.**
/// "How many local day boundaries has this card been overdue" needs the device
/// offset (BR-105, BR-161); SQL has no business knowing it, and `domain/` may
/// not read it (AD-16). So the boundary between them — this mapper — takes an
/// already-constructed [LocalDayModel] and hands the domain a plain integer.
///
/// **The `SUM`s arrive nullable and land as zero.** SQLite returns `NULL` for a
/// sum over no rows; a group only exists because it had rows, so in practice
/// neither is ever null — but a `!` here would be a crash on a shape the type
/// system already warned about, and the honest reading of "no rows matched that
/// branch" is zero.
abstract final class ReminderWorkloadMapper {
  static ReminderWorkloadModel toModel(
    ReminderWorkloadPerRootDeckResult row,
    LocalDayModel day,
  ) {
    final oldest = row.oldestOverdueAt;

    return ReminderWorkloadModel(
      deckId: row.rootDeckId,
      deckName: row.rootDeckName,
      overdueCount: row.overdueCount ?? 0,
      dueTodayCount: row.dueTodayCount ?? 0,
      overdueDayCount: oldest == null ? 0 : day.completedDaysSince(oldest),
    );
  }
}
