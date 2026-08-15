import 'package:workmanager/workmanager.dart';

/// The task name the background handler dispatches on.
const String kReminderTaskName = 'memox.daily_reminder';

/// The unique name of the pending run (BR-227).
///
/// **One name, and that is what makes reconciling idempotent.** WorkManager
/// keys pending work by unique name, so enqueueing again with
/// `ExistingWorkPolicy.replace` leaves exactly one run no matter how many times
/// bootstrap, a timezone change and a fired run all ask for one.
const String kReminderWorkName = 'memox.daily_reminder.next';

/// WorkManager, wrapped so nothing above `data/` sees it (AD-21).
///
/// **This owns WHEN, and only that.** It carries no notification, no database
/// and no copy: it enqueues a wake-up and cancels one. What happens at the
/// wake-up is `DeliverDailyReminderUseCase`, reached through the entry point in
/// `lib/app/reminder/`.
///
/// **Inexact by construction, which is the point** (BR-226). WorkManager
/// batches work against Doze and battery saver, so it needs no alarm permission
/// — and there is therefore no code path here that could ask for one. It also
/// persists its queue across reboot and app update on its own, which is the
/// whole of BR-226's "reschedule if the platform needs it".
final class ReminderSchedulerDataSource {
  ReminderSchedulerDataSource({Workmanager? workmanager})
    : _workmanager = workmanager ?? Workmanager();

  final Workmanager _workmanager;

  /// Registers the background entry point with the OS.
  ///
  /// [callbackDispatcher] must be a top-level function annotated with
  /// `@pragma('vm:entry-point')`; anything else is stripped by the Dart
  /// compiler and the wake-up then arrives at nothing.
  Future<void> initialize(Function callbackDispatcher) =>
      _workmanager.initialize(callbackDispatcher);

  /// Enqueues the next run [delay] from now, replacing any pending one.
  Future<void> scheduleIn(Duration delay) => _workmanager.registerOneOffTask(
    kReminderWorkName,
    kReminderTaskName,
    initialDelay: delay,
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );

  /// Drops the pending run. A no-op when there is none.
  Future<void> cancel() => _workmanager.cancelByUniqueName(kReminderWorkName);
}
