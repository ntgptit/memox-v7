import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/reminder_platform_repository_provider.dart';
import '../../di/reminder_settings_repository_provider.dart';
import '../../di/reminder_workload_repository_provider.dart';
import '../../domain/usecases/change_reminder_time_use_case.dart';
import '../../domain/usecases/deliver_daily_reminder_use_case.dart';
import '../../domain/usecases/disable_reminder_use_case.dart';
import '../../domain/usecases/enable_reminder_use_case.dart';
import '../../domain/usecases/reconcile_reminder_schedule_use_case.dart';
import '../../domain/usecases/watch_reminder_overview_use_case.dart';

part 'reminder_use_case_provider.g.dart';

/// The reminder feature's use cases, wired to their three contracts.
///
/// The same split `deck_use_case_provider.dart` documents: a file that only
/// wires dependencies is a `_provider`, never a `_controller`.
///
/// [reconcileReminderScheduleUseCase] is a dependency of three of the others
/// rather than something a screen calls, and it is declared here anyway —
/// bootstrap needs it by itself, and building a second instance inside each
/// caller would make "the schedule is derived from the row" true in four
/// places instead of one.
@riverpod
WatchReminderOverviewUseCase watchReminderOverviewUseCase(Ref ref) =>
    WatchReminderOverviewUseCase(
      ref.watch(reminderSettingsRepositoryProvider),
      ref.watch(reminderPlatformRepositoryProvider),
    );

@riverpod
ReconcileReminderScheduleUseCase reconcileReminderScheduleUseCase(Ref ref) =>
    ReconcileReminderScheduleUseCase(
      ref.watch(reminderSettingsRepositoryProvider),
      ref.watch(reminderPlatformRepositoryProvider),
    );

@riverpod
EnableReminderUseCase enableReminderUseCase(Ref ref) => EnableReminderUseCase(
  ref.watch(reminderSettingsRepositoryProvider),
  ref.watch(reminderPlatformRepositoryProvider),
  ref.watch(reconcileReminderScheduleUseCaseProvider),
);

@riverpod
DisableReminderUseCase disableReminderUseCase(Ref ref) => DisableReminderUseCase(
  ref.watch(reminderSettingsRepositoryProvider),
  ref.watch(reconcileReminderScheduleUseCaseProvider),
);

@riverpod
ChangeReminderTimeUseCase changeReminderTimeUseCase(Ref ref) =>
    ChangeReminderTimeUseCase(
      ref.watch(reminderSettingsRepositoryProvider),
      ref.watch(reconcileReminderScheduleUseCaseProvider),
    );

@riverpod
DeliverDailyReminderUseCase deliverDailyReminderUseCase(Ref ref) =>
    DeliverDailyReminderUseCase(
      ref.watch(reminderSettingsRepositoryProvider),
      ref.watch(reminderWorkloadRepositoryProvider),
      ref.watch(reminderPlatformRepositoryProvider),
    );
