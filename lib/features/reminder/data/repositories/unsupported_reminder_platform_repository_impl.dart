import '../../../../core/error/failure.dart';
import '../../domain/failures/reminder_failure.dart';
import '../../domain/models/reminder_capability_model.dart';
import '../../domain/models/reminder_summary_model.dart';
import '../../domain/models/reminder_time_model.dart';
import '../../domain/repositories/reminder_platform_repository.dart';

/// The reminder on a platform that has none — Web and iOS in this build
/// (BR-193, AD-04).
///
/// **A real implementation of the contract, not a null binding.** The screen
/// asks the same question it asks on Android and gets
/// [ReminderCapability.unsupported] back, so there is no `kIsWeb` in a widget,
/// no nullable repository, and no branch above `data/` that a future platform
/// would have to be added to.
///
/// **The writes throw rather than silently succeed.** A no-op `schedule` would
/// let the app store `enabled: true` against a platform that will never deliver
/// anything — a toggle that looks on and is not, which is precisely the state
/// BR-193 forbids. `EnableReminderUseCase` refuses before reaching here; these
/// throws are what makes that refusal impossible to bypass by calling the
/// repository directly.
///
/// [cancel] is the exception and stays a no-op: turning off something that was
/// never on must not fail, and `ReconcileReminderScheduleUseCase` calls it on
/// every launch of a disabled app — including on Web.
final class UnsupportedReminderPlatformRepositoryImpl
    implements ReminderPlatformRepository {
  const UnsupportedReminderPlatformRepositoryImpl();

  static const ConflictFailure _refusal = ConflictFailure(
    message: 'Reminders are not available on this platform',
    reason: ReminderSetupRejection.platformUnavailable,
  );

  @override
  Future<ReminderCapability> readCapability() async =>
      ReminderCapability.unsupported;

  @override
  Future<ReminderPermission> requestPermission() async =>
      ReminderPermission.notRequested;

  @override
  Future<void> schedule({
    required ReminderTime time,
    required DateTime now,
    required Duration utcOffset,
  }) async => throw _refusal;

  @override
  Future<void> cancel() async {}

  @override
  Future<void> showSummary(ReminderSummaryModel summary) async =>
      throw _refusal;
}
