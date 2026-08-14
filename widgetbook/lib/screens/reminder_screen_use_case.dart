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

/// The daily-reminder screen (UC-12, M6), in its three resting states.
///
/// The clock and the timezone are pinned for the reason the Study screens pin
/// theirs: `domain/` takes both as inputs (AD-06, AD-16), so a catalog that
/// left them real would show a different screen every day it was opened. Here
/// it decides nothing visible — the reminder time is stored, not derived — but
/// leaving a real clock in a catalog is how one creeps back in.
final DateTime _catalogNow = DateTime.utc(2026, 8, 8, 2);

/// What each dropdown entry sets up.
enum ReminderCatalogScenario {
  /// The state the screen opens in (BR-182): off, with the suggested time
  /// visible but not operable.
  off('Off (default)'),

  /// Enabled at a time the user picked, so the row is live and shows a value.
  on('On at 7:30 AM'),

  /// A platform with no reminder delivery (BR-193): the toggle is disabled and
  /// the screen says why rather than flipping and doing nothing.
  unavailable('Platform unavailable');

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
    ReminderCatalogScenario.off ||
    ReminderCatalogScenario.unavailable => ReminderSettingsModel.initial,
  };

  ReminderCapability get _capability =>
      scenario == ReminderCatalogScenario.unavailable
      ? ReminderCapability.unsupported
      : ReminderCapability.supported;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        reminderSettingsRepositoryProvider.overrideWithValue(
          ReminderCatalogSettings(_settings),
        ),
        reminderPlatformRepositoryProvider.overrideWithValue(
          ReminderCatalogPlatform(_capability),
        ),
        clockProvider.overrideWithValue(() => _catalogNow),
        utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
      ],
      child: const ReminderSettingsScreen(),
    );
  }
}
