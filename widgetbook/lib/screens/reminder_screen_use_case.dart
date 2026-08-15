import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/reminder/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminder/di/reminder_settings_repository_provider.dart';
import 'package:memox/features/reminder/domain/models/reminder_capability_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_settings_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_time_model.dart';
import 'package:memox/features/reminder/presentation/screens/reminder_settings_screen.dart';
import 'package:widgetbook/widgetbook.dart';

import 'reminder_catalog_repository.dart';

/// The daily-reminder screen (UC-17, M6), in every state it owns.
///
/// The clock and the timezone are pinned for the reason the Study screens pin
/// theirs: `domain/` takes both as inputs (AD-06, AD-16), so a catalog that
/// left them real would show a different screen every day it was opened. Here
/// it decides nothing visible — the reminder time is stored, not derived — but
/// leaving a real clock in a catalog is how one creeps back in.
final DateTime _catalogNow = DateTime.utc(2026, 8, 8, 2);

/// What each dropdown entry sets up.
enum ReminderCatalogScenario {
  /// The state the screen opens in (BR-218): off, with the suggested time
  /// visible but not operable.
  off('Off (default)'),

  /// Enabled at a time the user picked, so the row is live and shows a value.
  on('On at 7:30 AM'),

  /// A platform with no reminder delivery (BR-229): the toggle is disabled and
  /// the banner says so, rather than a control that flips and does nothing.
  unavailable('Platform unavailable'),

  /// The read never lands, so the spinner holds.
  loading('Loading (read never lands)'),

  /// The permission request stays in flight, so the busy face holds. Turn the
  /// toggle on to reach it.
  submitting('Submitting (turn it on)'),

  /// The OS refuses the prompt (BR-228). Turn the toggle on to reach it: the
  /// setting stays off, and the recovery is system settings, not another ask.
  permissionDenied('Permission denied (turn it on)'),

  /// The prompt is granted but the work will not enqueue (BR-226). Turn the
  /// toggle on to reach it.
  scheduleFailed('Schedule failed (turn it on)'),

  /// The pending run will not cancel. Turn the toggle on, then off — the copy
  /// here is deliberately not the schedule copy, because the setting *is*
  /// already off.
  cancelFailed('Cancel failed (on, then off)'),

  /// The choice will not write. Turn the toggle on to reach it.
  settingsWriteFailed('Settings write failed (turn it on)');

  const ReminderCatalogScenario(this.label);

  final String label;
}

WidgetbookComponent reminderSettingsScreenComponent() => WidgetbookComponent(
  name: 'ReminderSettingsScreen',
  useCases: <WidgetbookUseCase>[
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) {
        final scenario = context.knobs.object.dropdown<ReminderCatalogScenario>(
          label: 'scenario',
          options: ReminderCatalogScenario.values,
          labelBuilder: (ReminderCatalogScenario value) => value.label,
        );

        // Keyed by scenario so switching it rebuilds from scratch: the screen
        // reads its settings once through a stream provider, and a tree that
        // survived the switch would keep the previous scenario's.
        return _ReminderDemo(
          key: ValueKey<Object>(scenario),
          scenario: scenario,
        );
      },
    ),
  ],
);

class _ReminderDemo extends StatelessWidget {
  const _ReminderDemo({required this.scenario, super.key});

  final ReminderCatalogScenario scenario;

  ReminderSettingsModel get _settings => switch (scenario) {
    ReminderCatalogScenario.on => ReminderSettingsModel(
      isEnabled: true,
      time: ReminderTime.parse(7 * 60 + 30).time!,
    ),
    // Every failure scenario opens **off**, because that is where a user
    // stands when they reach for the toggle that then rejects them.
    _ => ReminderSettingsModel.initial,
  };

  ReminderCapability get _capability =>
      scenario == ReminderCatalogScenario.unavailable
      ? ReminderCapability.unsupported
      : ReminderCapability.supported;

  ReminderCatalogSettings get _settingsRepository => ReminderCatalogSettings(
    _settings,
    isRead: scenario != ReminderCatalogScenario.loading,
    doesWriteFail: scenario == ReminderCatalogScenario.settingsWriteFailed,
  );

  ReminderCatalogPlatform get _platform => ReminderCatalogPlatform(
    _capability,
    permission: scenario == ReminderCatalogScenario.permissionDenied
        ? ReminderPermission.denied
        : ReminderPermission.granted,
    doesScheduleFail: scenario == ReminderCatalogScenario.scheduleFailed,
    doesCancelFail: scenario == ReminderCatalogScenario.cancelFailed,
    doesPermissionStall: scenario == ReminderCatalogScenario.submitting,
  );

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        reminderSettingsRepositoryProvider.overrideWithValue(
          _settingsRepository,
        ),
        reminderPlatformRepositoryProvider.overrideWithValue(_platform),
        clockProvider.overrideWithValue(() => _catalogNow),
        utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
      ],
      child: const ReminderSettingsScreen(),
    );
  }
}
