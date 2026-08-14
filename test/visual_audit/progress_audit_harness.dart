import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/progress/di/progress_repository_provider.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';
import 'package:memox/features/progress/presentation/screens/progress_screen.dart';

import '../features/progress/presentation/support/fake_progress_repository.dart';

/// The instant every Progress audit renders at.
///
/// Fixed, and load-bearing rather than tidy: the chart's row labels are weekday
/// names derived from this instant, so an audit that read the wall clock would
/// render different words every day and a golden could not tell that apart from
/// a regression.
final DateTime kProgressAuditNow = DateTime.utc(2026, 8, 12, 12);

/// Wraps `ProgressScreen` in a `ProviderScope` over a fake repository.
///
/// **No `MaterialApp` here** — `auditMemoxScreen` supplies one, with the theme
/// for the brightness it is testing. A second one would pin the screen to a
/// single theme and hide exactly the dark-mode drift the audit exists to catch.
///
/// The offset is zero so the fixture's calendar dates and the dates the screen
/// renders are the same by construction; the offset arithmetic is tested where
/// it belongs, against the domain and against real SQLite.
Widget progressScreenWith({
  List<int> totals = const <int>[12, 0, 6, 143, 3, 9, 8],
  int streakDays = 5,
  bool? hasLifetimeActivity,
}) => _progressScreenOver(
  FakeProgressRepository(
    initial: progressOverviewFixture(
      totals: totals,
      streakDays: streakDays,
      today: DateTime.utc(2026, 8, 12),
      hasLifetimeActivity: hasLifetimeActivity,
    ),
  ),
);

/// The empty face (UC-12 A2): nobody has answered a card yet.
Widget progressScreenEmpty() => progressScreenWith(
  totals: const <int>[0, 0, 0, 0, 0, 0, 0],
  streakDays: 0,
  hasLifetimeActivity: false,
);

/// The streak-held face (UC-12 A1), which is the one loaded state whose hero
/// says something the normal state never does.
Widget progressScreenStreakHeld() =>
    progressScreenWith(totals: const <int>[4, 6, 3, 8, 5, 7, 0], streakDays: 6);

/// The error face (UC-12 E1).
///
/// Its own repository rather than a driven failure: the audit renders one frame
/// and inspects it, so a state that has to be *triggered* after mounting would
/// need the harness to know about timing it has no reason to know about.
Widget progressScreenFailing() =>
    _progressScreenOver(const _FailingProgressRepository());

Widget _progressScreenOver(ProgressRepository repository) => ProviderScope(
  overrides: [
    progressRepositoryProvider.overrideWithValue(repository),
    clockProvider.overrideWithValue(() => kProgressAuditNow),
    utcOffsetProvider.overrideWithValue(() => Duration.zero),
  ],
  child: const ProgressScreen(),
);

/// A read that fails immediately, for the error face.
class _FailingProgressRepository implements ProgressRepository {
  const _FailingProgressRepository();

  @override
  Stream<ProgressOverview> watchProgressOverview({
    required DateTime now,
    required Duration utcOffset,
  }) => Stream<ProgressOverview>.error(
    const DatabaseFailure(message: 'audit fixture failure'),
  );
}
