import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/reminder/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminder/di/reminder_settings_repository_provider.dart';
import 'package:memox/features/reminder/di/reminder_workload_repository_provider.dart';
import 'package:memox/features/reminder/presentation/screens/reminder_settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import 'fake_reminder_platform.dart';

/// Mounts `ReminderSettingsScreen` under a real theme, real localizations and
/// fake contracts.
///
/// **Shared because the geometry file outgrew the guard's 400-line ceiling**,
/// and splitting it left two files needing the same mount. A harness rather
/// than a copy: the two suites disagreeing about how the screen is pumped is
/// how one of them ends up green on a screen the other proves broken.
///
/// [platform] is a field rather than a constructor argument because several
/// tests replace it after construction — a stalled permission request, a
/// denied one — and the replacement has to land before [pump] runs.
class ReminderScreenHarness {
  ReminderScreenHarness()
    : settings = FakeReminderSettings(),
      platform = FakeReminderPlatform();

  /// Pinned, for the reason `domain/` takes both as inputs (AD-06, AD-16): a
  /// suite that left them real would measure a different screen tomorrow.
  static final DateTime now = DateTime.utc(2026, 7, 29, 3);
  static const Duration offset = Duration(hours: 7);

  FakeReminderSettings settings;
  FakeReminderPlatform platform;

  Future<void> pump(
    WidgetTester tester, {
    Size surface = const Size(393, 852),
    double textScale = 1,
    Locale locale = const Locale('en'),
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderSettingsRepositoryProvider.overrideWithValue(settings),
          reminderPlatformRepositoryProvider.overrideWithValue(platform),
          reminderWorkloadRepositoryProvider.overrideWithValue(
            FakeReminderWorkload(),
          ),
          clockProvider.overrideWithValue(() => now),
          utcOffsetProvider.overrideWithValue(() => offset),
        ],
        child: MaterialApp(
          theme: brightness == Brightness.dark
              ? buildDarkTheme()
              : buildLightTheme(),
          locale: locale,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          // `copyWith`, not a bare `MediaQueryData`: that constructor defaults
          // `size` to zero, so `CompactScaleWidget` read the app as compact
          // whatever [surface] said — the width this harness varies would
          // have forced the compact button padding and card-prompt size on
          // every case regardless of the surface under test.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            // **The compact scale, because the real app applies it here too**
            // (`app.dart`'s `MaterialApp.builder`). Without it every 320dp
            // case would render the roomy button padding and full-size card
            // prompt instead of the compact ones the real app shows there —
            // the screen gutter and `ListTileTheme.contentPadding` no longer
            // move with this tier, but the button and prompt scale still do.
            child: CompactScaleWidget(child: child ?? const SizedBox.shrink()),
          ),
          home: const ReminderSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}
