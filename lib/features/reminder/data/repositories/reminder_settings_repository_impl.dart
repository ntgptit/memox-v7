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
final class ReminderSettingsRepositoryImpl implements ReminderSettingsRepository {
  ReminderSettingsRepositoryImpl(this._dao, {required this.clock});

  final ReminderDao _dao;
  final DateTime Function() clock;

  @override
  Stream<ReminderSettingsModel> watchSettings() =>
      _dao.watchSettingsRow().map(ReminderSettingsMapper.toModel);

  @override
  Future<ReminderSettingsModel> readSettings() async =>
      ReminderSettingsMapper.toModel(await _dao.readSettingsRow());

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
      final mapped = mapDatabaseError(error);

      throw DatabaseFailure(
        message: mapped.message,
        cause: error,
        reason: ReminderSetupRejection.settingsWriteFailed,
      );
    }
  }
}
