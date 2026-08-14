import '../../../../core/error/drift_error_mapper.dart';
import '../../../../core/time/local_day_model.dart';
import '../../domain/models/reminder_workload_model.dart';
import '../../domain/repositories/reminder_workload_repository.dart';
import '../datasources/reminder_dao.dart';
import '../mappers/reminder_workload_mapper.dart';

/// The due workload, grouped by root deck (BR-184, BR-188).
///
/// **Read-only by construction.** The DAO it holds exposes one `SELECT` for this
/// path, so BR-189's "dismissing a reminder changes nothing" is not a discipline
/// anybody has to keep — there is no write to reach.
///
/// **`now` and the offset arrive as arguments, and one [LocalDayModel] is built
/// from them.** The same instance decides where the local day starts — which
/// splits overdue from due-today — and how many day boundaries the oldest
/// overdue card is behind. Building two would let the split and the age disagree
/// across a midnight that fell between them.
final class ReminderWorkloadRepositoryImpl implements ReminderWorkloadRepository {
  ReminderWorkloadRepositoryImpl(this._dao);

  final ReminderDao _dao;

  @override
  Future<List<ReminderWorkloadModel>> readWorkload({
    required DateTime now,
    required Duration utcOffset,
  }) async {
    final day = LocalDayModel(now: now, utcOffset: utcOffset);

    try {
      final rows = await _dao.readWorkloadRows(
        dayStart: day.startOfToday,
        now: now,
      );

      return <ReminderWorkloadModel>[
        for (final row in rows) ReminderWorkloadMapper.toModel(row, day),
      ];
    } on Object catch (error) {
      throw mapDatabaseError(error);
    }
  }
}
