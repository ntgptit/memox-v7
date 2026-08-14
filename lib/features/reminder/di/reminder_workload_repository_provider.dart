import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/reminder_workload_repository.dart';

part 'reminder_workload_repository_provider.g.dart';

/// The read-only workload the reminder is allowed to talk about (BR-184).
///
/// Declared as the contract and bound at the root, for the reason
/// `reminderSettingsRepositoryProvider` states.
@Riverpod(keepAlive: true)
ReminderWorkloadRepository reminderWorkloadRepository(Ref ref) =>
    throw StateError(
      'reminderWorkloadRepositoryProvider must be overridden at the '
      'composition root',
    );
