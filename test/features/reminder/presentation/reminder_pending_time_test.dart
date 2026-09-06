import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/reminder/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminder/di/reminder_settings_repository_provider.dart';
import 'package:memox/features/reminder/di/reminder_workload_repository_provider.dart';
import 'package:memox/features/reminder/domain/models/reminder_settings_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_time_model.dart';
import 'package:memox/features/reminder/presentation/screens/reminder_settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../support/fake_reminder_platform.dart';

/// The time on screen while a change is still in the air.
///
/// **The window is one frame, not the whole submit, and that correction matters
/// to what this file measures.** `ChangeReminderTimeUseCase` writes the new
/// time *before* it reconciles the schedule, and rolls it back only on failure
/// — so for most of a submit the persisted value already is the picked one, and
/// the old display rule showed the right thing by accident. The frame it got
/// wrong is the first one: `submit` sets `isSubmitting` and clears any previous
/// rejection synchronously, and the settings stream has not yet delivered the
/// optimistic write. On that frame the old rule fell back to the *abandoned*
/// stored time, on the one control the user had just pressed.
///
/// A one-frame flash of the wrong time is still the app changing its mind while
/// the user does nothing, and the rule that produced it was wrong for a reason
/// no timing accident should be relied on to hide: which time to show is not a
/// question about whether a database write has landed yet.
///
/// `FakeReminderSettings.saveGate` is what makes that frame reachable — the
/// same device `permissionGate` provides elsewhere in this fake, for the reason
/// recorded there: without it every command settles on the same microtask as
/// the tap, and a test claiming to measure "while submitting" measures "after
/// it finished".
void main() {
  final english = AppLocalizationsEn();
  final now = DateTime.utc(2026, 7, 29, 3);
  const offset = Duration(hours: 7);

  late FakeReminderSettings settings;
  late FakeReminderPlatform platform;

  setUp(() {
    // Enabled at 7:30 — the state the sibling file's `on (UC-17 S4)` group
    // uses, and the only one where there is a time row to look at.
    settings = FakeReminderSettings(
      ReminderSettingsModel(
        isEnabled: true,
        time: ReminderTime.parse(7 * 60 + 30).time!,
      ),
    );
    platform = FakeReminderPlatform();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
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
          theme: buildLightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ReminderSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Picks 9:00 through the dial's keyboard entry — the only deterministic way
  /// to set a time here, as the sibling file records.
  Future<void> pickNine(WidgetTester tester, {bool settle = true}) async {
    await tester.tap(find.text(english.reminderTimeLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '9');
    await tester.enterText(find.byType(TextField).last, '00');
    await tester.tap(find.text('OK'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('a first submit shows the pick before the write has landed', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.text('7:30 AM'), findsOneWidget, reason: 'stored A');

    // The optimistic write is held, so the frame under test is the one where
    // `isSubmitting` is the only thing that knows about the pick.
    final write = Completer<void>();
    settings.saveGate = write;

    await pickNine(tester, settle: false);

    // No rejection has ever occurred here, so this frame is reachable only
    // through `isSubmitting` — the half the old rule did not consult.
    expect(settings.current.time.minuteOfDay, 7 * 60 + 30, reason: 'unwritten');
    expect(find.text('9:00 AM'), findsOneWidget);
    expect(find.text('7:30 AM'), findsNothing);

    write.complete();
    await tester.pumpAndSettle();

    // And once it lands, B is on screen because it is persisted.
    expect(settings.current.time.minuteOfDay, 9 * 60);
    expect(find.text('9:00 AM'), findsOneWidget);
  });

  testWidgets('the picked time survives the whole retry, then persists', (
    tester,
  ) async {
    platform.shouldFailSchedule = true;
    await pumpScreen(tester);
    expect(find.text('7:30 AM'), findsOneWidget, reason: 'stored A');

    // B is picked and refused; the use case rolls the row back to A.
    await pickNine(tester);
    expect(find.text(english.reminderScheduleErrorTitle), findsOneWidget);
    expect(settings.current.time.minuteOfDay, 7 * 60 + 30);
    expect(find.text('9:00 AM'), findsOneWidget, reason: 'B after the refusal');

    // The retry begins, with its write held open.
    final write = Completer<void>();
    settings.saveGate = write;
    platform.shouldFailSchedule = false;
    await tester.tap(find.text(english.retryAction));
    await tester.pump();

    // **The frame the old rule got wrong.** The rejection cleared the instant
    // the command started; the write has not landed; the row must still name
    // the time the user is waiting on.
    expect(settings.current.time.minuteOfDay, 7 * 60 + 30);
    expect(
      find.text('9:00 AM'),
      findsOneWidget,
      reason: 'B must stay on screen while the retry is in flight',
    );
    expect(find.text('7:30 AM'), findsNothing);

    write.complete();
    await tester.pumpAndSettle();

    expect(settings.current.time.minuteOfDay, 9 * 60);
    expect(platform.scheduled.single.minuteOfDay, 9 * 60);
    expect(find.text('9:00 AM'), findsOneWidget);
    expect(find.text(english.reminderScheduleErrorTitle), findsNothing);
  });

  testWidgets('a retry that fails again never flashes the abandoned time', (
    tester,
  ) async {
    platform.shouldFailSchedule = true;
    await pumpScreen(tester);
    await pickNine(tester);
    expect(find.text('9:00 AM'), findsOneWidget);

    final write = Completer<void>();
    settings.saveGate = write;
    await tester.tap(find.text(english.retryAction));
    await tester.pump();

    expect(find.text('9:00 AM'), findsOneWidget, reason: 'in flight');
    expect(find.text('7:30 AM'), findsNothing);

    write.complete();
    await tester.pumpAndSettle();

    // Refused again: the banner is back, the row still names the time the
    // banner is offering to re-submit, and nothing flashed in between.
    expect(find.text(english.reminderScheduleErrorTitle), findsOneWidget);
    expect(settings.current.time.minuteOfDay, 7 * 60 + 30);
    expect(find.text('9:00 AM'), findsOneWidget);
  });

  testWidgets(
    'once it settles cleanly the stored time is authoritative again',
    (tester) async {
      await pumpScreen(tester);
      await pickNine(tester);

      // A successful change persists B, so B is shown for the ordinary reason.
      // This is the guard on the other side: the rule must not pin a draft
      // forever, or the row would keep naming a time the database does not
      // hold with no banner beside it to say why.
      expect(settings.current.time.minuteOfDay, 9 * 60);
      expect(find.text('9:00 AM'), findsOneWidget);
      expect(find.text(english.reminderScheduleErrorTitle), findsNothing);
    },
  );
}
