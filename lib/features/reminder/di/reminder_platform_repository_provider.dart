import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/reminder_platform_repository.dart';

part 'reminder_platform_repository_provider.g.dart';

/// The device half of the reminder (AD-21).
///
/// **This is the provider whose binding decides the platform.** Two
/// implementations satisfy it — the Android adapter and the unsupported one —
/// and choosing between them is the composition root's job, which is what keeps
/// every `kIsWeb` and every `defaultTargetPlatform` out of `domain/` and
/// `presentation/` (BR-229).
@Riverpod(keepAlive: true)
ReminderPlatformRepository reminderPlatformRepository(Ref ref) =>
    throw StateError(
      'reminderPlatformRepositoryProvider must be overridden at the '
      'composition root',
    );
