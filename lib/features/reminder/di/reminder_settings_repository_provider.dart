import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/reminder_settings_repository.dart';

part 'reminder_settings_repository_provider.g.dart';

/// The stored half of the reminder, declared as the **contract** and bound at
/// the composition root.
///
/// The same shape every other feature's repository provider has, and for the
/// same reason: `features/` may never import `app/` (AD-13), so the feature
/// states what it requires and `app/di/repository_bindings.dart` decides what
/// satisfies it. The body throws because `presentation/` may not name an
/// `*Impl`; a missing binding is a `StateError` on the first read, which
/// happens as the reminder screen mounts.
@Riverpod(keepAlive: true)
ReminderSettingsRepository reminderSettingsRepository(Ref ref) =>
    throw StateError(
      'reminderSettingsRepositoryProvider must be overridden at the '
      'composition root',
    );
