import '../../../../core/error/failure.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/failures/reminder_failure.dart';
import '../../domain/models/reminder_capability_model.dart';
import '../../domain/models/reminder_summary_model.dart';
import '../../domain/models/reminder_time_model.dart';
import '../../domain/repositories/reminder_platform_repository.dart';
import '../datasources/reminder_notification_data_source.dart';
import '../datasources/reminder_scheduler_data_source.dart';
import '../mappers/reminder_message_mapper.dart';

/// The device half of the reminder on Android (AD-21).
///
/// **Two collaborators because there are two jobs.** The scheduler owns *when*
/// and the notifier owns *what is shown*; keeping them apart is what lets the
/// fire-time path exist at all — the wake-up runs Dart, re-reads the workload,
/// and only then decides whether anything gets posted (BR-184).
///
/// **Every plugin exception is re-typed here.** Above this file a caller sees a
/// `Failure` carrying a [ReminderSetupRejection], never a `PlatformException`
/// — which is what keeps the UI from having to know what a platform channel is
/// (AD-01), and what makes "the OS refused the work" a state the screen can
/// offer a retry for.
final class AndroidReminderPlatformRepositoryImpl
    implements ReminderPlatformRepository {
  AndroidReminderPlatformRepositoryImpl({
    required ReminderNotificationDataSource notifier,
    required ReminderSchedulerDataSource scheduler,
    AppLocalizations Function()? localizations,
    // ignore_for_file: prefer_initializing_formals -- reason: Dart forbids a
    // named parameter starting with an underscore, so `required this._notifier`
    // does not compile and the fields have to be assigned in the initializer
    // list. Making them public to satisfy the lint would widen the API of a
    // data-layer class for a style rule.
  }) : _notifier = notifier,
       _scheduler = scheduler,
       _localizations =
           localizations ?? ReminderMessageMapper.localizationsForDevice;

  final ReminderNotificationDataSource _notifier;
  final ReminderSchedulerDataSource _scheduler;
  final AppLocalizations Function() _localizations;

  @override
  Future<ReminderCapability> readCapability() => _notifier.readCapability();

  @override
  Future<ReminderPermission> requestPermission() async {
    try {
      return await _notifier.requestPermission();
    } on Object {
      // A channel that will not answer is indistinguishable, from here, from a
      // user who said no: either way the app may not post, and the screen shows
      // the same recoverable state (BR-192).
      return ReminderPermission.denied;
    }
  }

  @override
  Future<void> schedule({
    required ReminderTime time,
    required DateTime now,
    required Duration utcOffset,
    DateTime? notBefore,
  }) async {
    // The occurrence is chosen from `notBefore`; the delay is measured from
    // `now`. WorkManager counts `initialDelay` forward from the moment it
    // accepts the work, so measuring it from anything later than the wall clock
    // fires the reminder early by exactly that gap — and the gap repeats every
    // night, so the reminder walks backwards through the day.
    final fireAt = time.nextOccurrenceAfter(notBefore ?? now, utcOffset);
    final delay = fireAt.difference(now);

    try {
      // Clamped: a caller that supplied a `notBefore` in the past would
      // otherwise ask the OS for a negative delay, which is a schedule nobody
      // can reason about. Zero means "as soon as the OS is willing".
      await _scheduler.scheduleIn(delay.isNegative ? Duration.zero : delay);
    } on Object catch (error) {
      throw ConflictFailure(
        message: 'The system refused the reminder work',
        cause: error,
        reason: ReminderSetupRejection.scheduleFailed,
      );
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _scheduler.cancel();
      await _notifier.cancel();
    } on Object catch (error) {
      throw ConflictFailure(
        message: 'The pending reminder work could not be cancelled',
        cause: error,
        reason: ReminderSetupRejection.scheduleFailed,
      );
    }
  }

  @override
  Future<void> showSummary(ReminderSummaryModel summary) async {
    final l10n = _localizations();
    final message = ReminderMessageMapper.toMessage(summary, l10n);

    await _notifier.initialize();
    await _notifier.show(
      title: message.title,
      body: message.body,
      channelName: l10n.reminderChannelName,
      channelDescription: l10n.reminderChannelDescription,
    );
  }
}
