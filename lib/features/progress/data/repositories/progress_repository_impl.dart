import '../../../../core/error/drift_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/time/local_day_model.dart';
import '../../domain/models/progress_overview_model.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_dao.dart';
import '../mappers/progress_mapper.dart';

/// The Drift-backed [ProgressRepository] (UC-12).
///
/// **Nothing in here writes, and nothing in here can.** [ProgressDao] exposes a
/// single read and no transaction helper, so BR-190 is not a rule this class
/// remembers to follow — it is a rule the surface it depends on cannot break.
///
/// A `DriftException` never crosses this boundary: every emission goes through
/// [_guardStream], which rethrows a domain [Failure] untouched and maps anything
/// else through `mapDatabaseError`. The UI is shown a `Failure` and never a
/// table name (BR-52).
final class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._dao);

  final ProgressDao _dao;

  @override
  Stream<ProgressOverview> watchProgressOverview({
    required DateTime now,
    required Duration utcOffset,
  }) {
    // Built once, outside the `map`, so every emission of this subscription is
    // measured against the same instant (BR-184). Constructing it per emission
    // would make a live refresh silently re-anchor the window to a newer clock
    // reading, and the screen would then roll over at an arbitrary answer rather
    // than at midnight — which is a rollover nobody scheduled and no test would
    // reproduce twice.
    final day = LocalDayModel(now: now, utcOffset: utcOffset);

    return _guardStream(
      _dao.watchActivityDays(utcOffset: utcOffset),
    ).map((rows) => overviewFromRows(rows, day: day));
  }

  Stream<T> _guardStream<T>(Stream<T> source) =>
      source.handleError(_rethrowMapped);

  Never _rethrowMapped(Object error) {
    if (error is Failure) throw error;
    throw mapDatabaseError(error);
  }
}
