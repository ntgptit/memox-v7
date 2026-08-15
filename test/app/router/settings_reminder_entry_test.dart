import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/reminder/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminder/di/reminder_settings_repository_provider.dart';
import 'package:memox/features/reminder/di/reminder_workload_repository_provider.dart';
import 'package:memox/features/reminder/domain/models/reminder_settings_model.dart';
import 'package:memox/features/reminder/presentation/screens/reminder_settings_screen.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';
import 'package:memox/features/settings/presentation/widgets/sections/settings_reminder_entry_section_widget.dart';
import 'package:memox/features/study/di/study_home_repository_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../../features/deck/presentation/support/fake_deck_repository.dart';
import '../../features/reminder/support/fake_reminder_platform.dart';
import '../../features/settings/domain/support/fake_app_settings_repository.dart';
import '../../features/study/domain/support/fake_study_home_repository.dart';
import '../../features/study/domain/support/fake_study_repository.dart';

/// The way into the daily reminder, through the real route table (UC-17
/// trigger, wireframe M6 W1).
///
/// **This is a reachability test, and it exists because nothing else was one.**
/// The reminder feature arrived from a branch where the Settings branch was
/// still a placeholder, so its route was defined, its screen was built and
/// tested, its deep link worked — and no screen in the app linked to it. Every
/// gate stayed green: the route resolves, the screen renders, the ARB key is
/// used. A route with no call site is invisible to all of them.
///
/// So the assertion is deliberately end-to-end rather than "the widget calls
/// `goNamed`": a unit test of the callback would have passed on the day the row
/// did not exist at all.
void main() {
  final english = AppLocalizationsEn();

  Future<GoRouter> pumpAt(WidgetTester tester, String location) async {
    final router = createAppRouter(initialLocation: location);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          appSettingsRepositoryProvider.overrideWithValue(
            FakeAppSettingsRepository(),
          ),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          studyHomeRepositoryProvider.overrideWithValue(
            FakeStudyHomeRepository(),
          ),
          studyRepositoryProvider.overrideWithValue(FakeStudyRepository()),
          // Deliberately **on**, so a row that mirrored reminder state would
          // have something to mirror. Seeded off, the second test below would
          // pass on a row that leaks.
          reminderSettingsRepositoryProvider.overrideWithValue(
            FakeReminderSettings(
              ReminderSettingsModel.initial.copyWith(isEnabled: true),
            ),
          ),
          reminderWorkloadRepositoryProvider.overrideWithValue(
            FakeReminderWorkload(),
          ),
          reminderPlatformRepositoryProvider.overrideWithValue(
            FakeReminderPlatform(),
          ),
        ],
        child: MemoxApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    return router;
  }

  testWidgets('Settings offers a row that opens the daily reminder', (
    tester,
  ) async {
    final router = await pumpAt(tester, RoutePaths.settings);

    final row = find.byType(SettingsReminderEntrySectionWidget);
    expect(row, findsOneWidget, reason: 'UC-17 has no other trigger');

    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();

    // Built from the two constants rather than written out: a test holding its
    // own copy of the location agrees with itself after someone moves the
    // screen, which is the one change this test exists to notice.
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '${RoutePaths.settings}/${RoutePaths.reminderSettingsRelative}',
    );
    expect(find.byType(ReminderSettingsScreen), findsOneWidget);
  });

  testWidgets('the row carries the reminder title and stays stateless', (
    tester,
  ) async {
    await pumpAt(tester, RoutePaths.settings);

    final row = find.byType(SettingsReminderEntrySectionWidget);
    expect(
      find.descendant(of: row, matching: find.text(english.reminderTitle)),
      findsOneWidget,
    );

    // M6 R1: the row says nothing about whether the reminder is on. Showing it
    // would make `features/settings/` watch `features/reminder/`'s state, which
    // is the cross-feature dependency the architecture guard refuses — and the
    // fake here is deliberately enabled, so a row that leaked state would have
    // something to leak.
    for (final leaked in <String>[
      english.reminderStatusOn,
      english.reminderStatusOff,
    ]) {
      expect(
        find.descendant(of: row, matching: find.text(leaked)),
        findsNothing,
        reason: 'the row must not mirror reminder state',
      );
    }
  });
}
