import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/time/clock_provider.dart';
import '../../core/time/time_zone_provider.dart';
import '../../features/reminder/data/datasources/reminder_scheduler_data_source.dart';
import '../../features/reminder/presentation/providers/reminder_use_case_provider.dart';
import '../di/repository_bindings.dart';

/// What the operating system wakes up at reminder time (AD-21).
///
/// **A second composition root, and it has to be.** WorkManager runs this in a
/// background isolate with no widget tree, no `ProviderScope` and no access to
/// anything the app isolate is holding — so the container is built here from the
/// same [repositoryBindingOverrides] list the app uses. The list is what makes
/// the two roots agree: a binding that grows a dependency cannot break this one
/// without breaking the app as well, which is exactly the failure that a
/// hand-written subset of it caused in the integration harness.
///
/// **It opens a second connection to the same SQLite file.** Two isolates, two
/// connections, one file — which SQLite handles, and which is the price AD-21
/// records for re-reading the workload at fire time instead of trusting a
/// payload written the day before.
@pragma('vm:entry-point')
void reminderCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != kReminderTaskName) return true;

    return runDailyReminderTask();
  });
}

/// One fire-time run: deliver if anything is owed, then queue tomorrow's.
///
/// **It returns `true` for every outcome, including the two skips.** A `false`
/// return is `Result.retry()` to WorkManager, and both skips are correct
/// outcomes (BR-184): re-waking the app to re-discover the same emptiness buys
/// nothing, and on the `skippedDisabled` path the reconcile below has just
/// *cancelled* this work — asking the OS to retry work we cancelled is a
/// contradiction, whichever of the two happens to win.
///
/// **The reschedule runs in a `finally`.** If the delivery throws — a database
/// that will not open, a plugin that will not answer — the chain must not stop
/// there: a reminder that silently ends after one bad night is worse than a
/// missed notification, and there is nobody around to notice.
///
/// **The container is always disposed**, which is what closes the database. A
/// leaked connection in a background isolate holds a file lock the app isolate
/// then contends with.
///
/// `@visibleForTesting` is deliberately absent: a host test drives
/// `DeliverDailyReminderUseCase` directly with fakes, because this function's
/// whole job is the wiring a host has no way to exercise.
Future<bool> runDailyReminderTask() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer(overrides: repositoryBindingOverrides());

  try {
    final now = container.read(clockProvider)();
    final utcOffset = container.read(utcOffsetProvider)();

    try {
      final outcome = await container.read(deliverDailyReminderUseCaseProvider)(
        now: now,
        utcOffset: utcOffset,
      );
      _log('reminder delivery: ${outcome.name}');

      return true;
    } finally {
      // **No anchor is passed here.** BR-185's day skip is derived inside the
      // reconcile from the delivery this run just recorded, so the launch
      // reconcile and this one reach the same answer — which they did not while
      // the anchor was a parameter only the worker supplied.
      await container.read(reconcileReminderScheduleUseCaseProvider)(
        now: now,
        utcOffset: utcOffset,
      );
    }
  } on Object catch (error, stackTrace) {
    // Width is deliberate: a database failure, a plugin failure and a
    // programming error all land here, and none of them may crash a background
    // isolate the user cannot see. The next run is already queued by the
    // `finally` above unless that threw too, in which case the app repairs the
    // schedule on its next launch.
    _log('reminder run failed', error: error, stackTrace: stackTrace);

    return false;
  } finally {
    container.dispose();
  }
}

/// Diagnostics for the one code path with no screen behind it.
///
/// **No count, no deck name, no copy** (BR-186). The outcome enum is the whole
/// of what is written, and it says what happened without saying anything about
/// what the user is studying.
void _log(String message, {Object? error, StackTrace? stackTrace}) =>
    developer.log(
      message,
      name: 'memox.reminder',
      error: error,
      stackTrace: stackTrace,
      level: error == null ? 800 : 900,
    );
