import 'package:flutter/foundation.dart';

import '../../features/reminder/data/datasources/reminder_notification_data_source.dart';
import '../../features/reminder/data/datasources/reminder_scheduler_data_source.dart';
import 'reminder_worker_entry.dart';

/// Registers the reminder's two OS-facing pieces once per app launch (AD-21).
///
/// **Composition-root work, so it lives in `app/`.** It names both data sources
/// and the background entry point, which is exactly the wiring a feature is not
/// allowed to do for itself (AD-13) — and the same reason
/// `repository_bindings.dart` is the only file that names an `*Impl`.
///
/// Two registrations, both idempotent:
///
/// * the notification plugin, so a tap that arrives while the app is running has
///   somewhere to go (BR-189);
/// * WorkManager's callback dispatcher, so a wake-up finds an entry point rather
///   than an empty isolate.
///
/// **Neither runs off Android** (BR-193). `kIsWeb` is checked first because
/// `defaultTargetPlatform` on the web reports the *browser's host OS* — an
/// Android phone in Chrome answers `TargetPlatform.android`, and the web build
/// would then call plugins it has no business calling.
///
/// **A cold start launched by a tap is handled here too.** The plugin's
/// in-process callback only fires while the app is alive; a launch *from* a
/// notification is reported once, through the launch details, and asking for it
/// anywhere later means the first tap of the day opens the deck list.
Future<void> initializeReminderPlatform({
  required void Function() onOpenStudy,
  ReminderNotificationDataSource? notifier,
  ReminderSchedulerDataSource? scheduler,
}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

  final notifications = notifier ?? ReminderNotificationDataSource();
  final work = scheduler ?? ReminderSchedulerDataSource();

  await notifications.initialize(
    onTap: (payload) {
      if (payload != kReminderTapPayload) return;

      onOpenStudy();
    },
  );
  await work.initialize(reminderCallbackDispatcher);

  final launchPayload = await notifications.readLaunchPayload();
  if (launchPayload != kReminderTapPayload) return;

  onOpenStudy();
}
