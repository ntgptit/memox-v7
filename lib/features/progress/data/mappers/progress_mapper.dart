import '../../../../core/database/app_database.dart';
import '../../../../core/time/local_day_model.dart';
import '../../domain/models/progress_activity_day_model.dart';
import '../../domain/models/progress_overview_model.dart';

/// Milliseconds in a second — the one conversion between SQLite's unix seconds
/// and Dart's millisecond epoch.
const int _kMillisecondsPerSecond = 1000;

/// Drift rows → the domain snapshot (AD-01).
///
/// **Translation only.** Everything that is a *rule* — the seven-day window, the
/// zero-fill, the streak walk — lives in `ProgressOverview.fromActivity`, where
/// it can be tested without a database. What is left here is the one thing the
/// domain must not know: that a day arrives as an integer number of seconds.
ProgressActivityDay activityDayFromRow(
  ProgressActivityDaysResult row,
) => ProgressActivityDay(
  // Already a local midnight in the shifted frame, so this is a relabelling
  // and not a calculation. Doing the offset arithmetic again here is how the
  // mapper and the query end up disagreeing about which day a row is in —
  // and they would disagree only for the answers within one offset of
  // midnight, which is the hardest case to notice and the easiest to write.
  localDate: DateTime.fromMillisecondsSinceEpoch(
    row.localDayStart * _kMillisecondsPerSecond,
    isUtc: true,
  ),
  totalCards: row.totalCards,
  learningCards: row.learningCards,
);

/// One emission of the Progress screen (UC-12).
///
/// [day] carries the single `now`/offset snapshot the whole emission is measured
/// against (BR-184) — the same one whose `utcOffset` produced these rows.
ProgressOverview overviewFromRows(
  List<ProgressActivityDaysResult> rows, {
  required LocalDayModel day,
}) => ProgressOverview.fromActivity(
  activityDays: rows.map(activityDayFromRow).toList(growable: false),
  day: day,
);
