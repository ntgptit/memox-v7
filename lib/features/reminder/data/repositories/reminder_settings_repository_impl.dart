import '../../../../core/error/drift_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../domain/failures/reminder_failure.dart';
import '../../domain/models/reminder_settings_model.dart';
import '../../domain/models/reminder_time_model.dart';
import '../../domain/repositories/reminder_settings_repository.dart';
import '../datasources/reminder_dao.dart';
import '../mappers/reminder_settings_mapper.dart';

/// The stored reminder choice, over the one-row `app_settings` table.
///
/// **The clock is injected.** `updated_at` is the settings row's own timestamp
/// and it is a real fact about the row, so it is stamped from `clockProvider`
/// rather than from `DateTime.now()` — the same reason nothing else in
/// `lib/features/` reads the wall clock (AD-16).
///
/// Drift exceptions stop here (AD-01). They are mapped through
/// [mapDatabaseError] and then re-typed with
/// [ReminderSetupRejection.settingsWriteFailed], so the screen can tell "your
/// choice was not saved" apart from "the OS would not take the schedule" —
/// two failures with two different retries.
final class ReminderSettingsRepositoryImpl
    implements ReminderSettingsRepository {
  ReminderSettingsRepositoryImpl(this._dao, {required this.clock});

  final ReminderDao _dao;
  final DateTime Function() clock;

  /// **Errors are mapped here too, not left raw** (AD-01). A one-row table can
  /// still throw — `watchSingle` on no rows, or a file that will not open — and
  /// a `StateError` arriving in the UI as "some error" is the boundary leaking,
  /// even where the screen happens to render the same copy either way.
  @override
  Stream<ReminderSettingsModel> watchSettings() => _dao
      .watchSettingsRow()
      .map(ReminderSettingsMapper.toModel)
      .handleError((Object error) => throw _asFailure(error));

  /// **Wrapped, like the write.** `getSingle()` throws a raw `StateError` when
  /// the one-row table somehow holds none, and a Drift exception when the file
  /// will not open. Both use cases call this *before* their own `try`, and the
  /// controllers catch `on Failure` — so an unmapped throw escaped through
  /// `unawaited`, left the command at `isSubmitting: true` for good, and locked
  /// the toggle with no banner to explain it (AD-01).
  @override
  Future<ReminderSettingsModel> readSettings() async {
    try {
      return ReminderSettingsMapper.toModel(await _dao.readSettingsRow());
    } on Object catch (error) {
      throw _asFailure(error);
    }
  }

  @override
  Future<void> markDelivered(DateTime deliveredAt) async {
    try {
      await _dao.writeDelivered(deliveredAt);
    } on Object catch (error) {
      throw _asFailure(error);
    }
  }

  /// One mapping for every path out of this repository.
  Failure _asFailure(Object error) => DatabaseFailure(
    message: mapDatabaseError(error).message,
    cause: error,
    reason: ReminderSetupRejection.settingsWriteFailed,
  );

  @override
  Future<void> saveSettings({
    required bool isEnabled,
    required ReminderTime time,
  }) async {
    try {
      await _dao.writeSettings(
        isEnabled: isEnabled,
        minuteOfDay: time.minuteOfDay,
        updatedAt: clock(),
      );
    } on Object catch (error) {
      throw _asFailure(error);
    }
  }
}
