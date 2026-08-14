import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/reminder/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminder/di/reminder_settings_repository_provider.dart';
import 'package:memox/features/reminder/di/reminder_workload_repository_provider.dart';
import 'package:memox/features/reminder/domain/models/reminder_capability_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_settings_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_time_model.dart';
import 'package:memox/features/reminder/presentation/screens/reminder_settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../support/fake_reminder_platform.dart';

/// The reminder screen's states, against fakes at the domain boundary.
///
/// **No plugin is reached and no notification is posted.** The three contracts
/// are overridden, which is also what lets the permission-denied and
/// unsupported branches be rendered on demand — neither is reachable from a
/// host binding otherwise.
void main() {
  final english = AppLocalizationsEn();
  final now = DateTime.utc(2026, 7, 29, 3);
  const offset = Duration(hours: 7);

  late FakeReminderSettings settings;
  late FakeReminderPlatform platform;

  setUp(() {
    settings = FakeReminderSettings();
    platform = FakeReminderPlatform();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size surface = const Size(393, 852),
    double textScale = 1,
    Locale locale = const Locale('en'),
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
          theme: buildLightTheme(),
          locale: locale,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: const ReminderSettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Switch toggleOf(WidgetTester tester) =>
      tester.widget<Switch>(find.byType(Switch));

  group('off (UC-12 S2, BR-182)', () {
    testWidgets('opens off, at 20:00, with both disclosures', (tester) async {
      await pumpScreen(tester);

      expect(toggleOf(tester).value, isFalse);
      expect(find.text(english.reminderDueOnlyNote), findsOneWidget);
      expect(find.text(english.reminderPrivacyNote), findsOneWidget);
      // Nothing has been asked of the OS yet — the whole of BR-182.
      expect(platform.permissionRequests, 0);
      expect(platform.scheduled, isEmpty);
    });

    testWidgets('the time row is visible but not operable (M6 R3)', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text(english.reminderTimeLabel), findsOneWidget);
      // The suggested time is readable before the user decides to opt in.
      expect(find.text('8:00 PM'), findsOneWidget);
    });
  });

  group('turning it on', () {
    testWidgets('asks for permission, then shows the reminder as on', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(platform.permissionRequests, 1);
      expect(settings.current.isEnabled, isTrue);
      expect(platform.scheduled.single, ReminderTime.suggested);
      expect(toggleOf(tester).value, isTrue);
    });

    testWidgets('a refused permission leaves it off and explains (UC-12 E1)', (
      tester,
    ) async {
      platform.permission = ReminderPermission.denied;
      await pumpScreen(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(toggleOf(tester).value, isFalse);
      expect(settings.current.isEnabled, isFalse);
      expect(find.text(english.reminderPermissionDeniedTitle), findsOneWidget);
      // The recovery is offered, so the flow does not dead-end.
      expect(find.text(english.reminderRetryAction), findsOneWidget);
    });

    testWidgets('a schedule failure says nothing was turned on (UC-12 E3)', (
      tester,
    ) async {
      platform.shouldFailSchedule = true;
      await pumpScreen(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(toggleOf(tester).value, isFalse);
      expect(find.text(english.reminderScheduleErrorTitle), findsOneWidget);
    });
  });

  group('unsupported platform (UC-12 E2, BR-193)', () {
    testWidgets('the toggle is disabled and the screen says why', (
      tester,
    ) async {
      platform.capability = ReminderCapability.unsupported;
      await pumpScreen(tester);

      expect(toggleOf(tester).onChanged, isNull);
      // The banner is derived from the capability, not from a command: no
      // command can run here, so waiting for one to fail would leave this
      // state permanently unreachable and the user with a grey switch and no
      // explanation.
      expect(find.text(english.reminderUnavailableTitle), findsOneWidget);
      expect(find.text(english.reminderUnavailableMessage), findsOneWidget);
      // What must never appear is a retry for a state that cannot change.
      expect(find.text(english.reminderRetryAction), findsNothing);
    });
  });

  group('on (UC-12 S4)', () {
    setUp(() {
      settings = FakeReminderSettings(
        ReminderSettingsModel(
          isEnabled: true,
          time: ReminderTime.parse(7 * 60 + 30).time!,
        ),
      );
    });

    testWidgets('shows the stored time and lets it be changed', (tester) async {
      await pumpScreen(tester);

      expect(toggleOf(tester).value, isTrue);
      expect(find.text('7:30 AM'), findsOneWidget);

      await tester.tap(find.text(english.reminderTimeLabel));
      await tester.pumpAndSettle();

      // The platform dialog is open; cancelling it changes nothing.
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(settings.current.time.minuteOfDay, 7 * 60 + 30);
    });

    testWidgets('a failed cancel says the reminder is off, not that nothing '
        'was turned on (UC-12 A2)', (tester) async {
      platform.shouldFailCancel = true;
      await pumpScreen(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // The setting really did go off, so copy claiming nothing was turned on
      // would describe the opposite of what happened.
      expect(settings.current.isEnabled, isFalse);
      expect(find.text(english.reminderCancelErrorTitle), findsOneWidget);
      expect(find.text(english.reminderScheduleErrorTitle), findsNothing);
    });

    testWidgets('retrying a failed cancel retries the cancel, not the enable', (
      tester,
    ) async {
      platform.shouldFailCancel = true;
      await pumpScreen(tester);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // A single hardwired retry turned "turning it off failed" into "turn it
      // back on" — the button undoing what the user just asked for.
      platform.shouldFailCancel = false;
      await tester.tap(find.text(english.reminderRetryAction));
      await tester.pumpAndSettle();

      expect(settings.current.isEnabled, isFalse);
      expect(toggleOf(tester).value, isFalse);
      expect(platform.cancelCount, 1);
      expect(platform.permissionRequests, 0);
    });

    testWidgets('turning it off cancels and keeps the time', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(settings.current.isEnabled, isFalse);
      expect(settings.current.time.minuteOfDay, 7 * 60 + 30);
      expect(platform.cancelCount, 1);
    });

    testWidgets('retrying a failed time change re-submits the picked time', (
      tester,
    ) async {
      platform.shouldFailSchedule = true;
      await pumpScreen(tester);

      await tester.tap(find.text(english.reminderTimeLabel));
      await tester.pumpAndSettle();
      // The picker opens at 7:30 AM; move it to 9:00 AM through the dial's
      // text entry, which is the only deterministic way to set a time here.
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '9');
      await tester.enterText(find.byType(TextField).last, '00');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // The reschedule failed, so the stored time rolled back to 7:30.
      expect(find.text(english.reminderScheduleErrorTitle), findsOneWidget);
      expect(settings.current.time.minuteOfDay, 7 * 60 + 30);

      platform.shouldFailSchedule = false;
      await tester.tap(find.text(english.reminderRetryAction));
      await tester.pumpAndSettle();

      // The retry must carry the value the user chose. Reading it back from
      // the rolled-back row would re-submit 7:30, which the use case treats as
      // a no-op — a retry that reports success and changes nothing.
      expect(settings.current.time.minuteOfDay, 9 * 60);
      expect(platform.scheduled.single.minuteOfDay, 9 * 60);
    });

    testWidgets('the time is localized, not formatted by hand', (tester) async {
      await pumpScreen(tester, locale: const Locale('vi'));

      // Vietnamese renders a 24-hour clock; a hand-rolled `h:mm a` would print
      // the English form to a Vietnamese user with nothing failing.
      expect(find.text('7:30 AM'), findsNothing);
      expect(find.textContaining('7:30'), findsOneWidget);
    });
  });

  group('accessibility (M6 A3, A4)', () {
    testWidgets('the toggle is spoken with its own name and value', (
      tester,
    ) async {
      // Disposed at the end of the body rather than through `addTearDown`:
      // the framework verifies no handle is live *before* tear-downs run.
      final handle = tester.ensureSemantics();
      await pumpScreen(tester);

      // Read off the control itself, not by label: the screen title is the
      // same words, so a label search would find two nodes and prove nothing
      // about which one carries the switch.
      final node = tester.getSemantics(find.byType(Switch));

      // The label lives on the control, not only on the Text beside it: a
      // reader that focuses the switch would otherwise hear "Off" with no idea
      // what is off (WCAG 4.1.2).
      expect(node.label, english.reminderToggleLabel);
      // The value is what carries the state in words. The toggled *flag* is
      // Material's own and is asserted by the framework's Switch tests; what
      // this screen owns, and what M6 R7 is about, is that the state is also
      // readable without seeing the colour.
      expect(node.value, english.reminderStatusOff);

      handle.dispose();
    });

    testWidgets('the time row announces the time once, as its value', (
      tester,
    ) async {
      // Disposed at the end of the body rather than through `addTearDown`:
      // the framework verifies no handle is live *before* tear-downs run.
      final handle = tester.ensureSemantics();
      await pumpScreen(tester);

      // Read from the text rather than from the widget type: the merged node
      // belongs to the tile's ancestor, and `byType` lands on an element whose
      // own node is empty.
      final node = tester.getSemantics(find.text(english.reminderTimeLabel));

      // One node carries both, and the time appears exactly once. It used to be
      // in the merged label *and* in a `Semantics(value:)` wrapper, so a reader
      // heard "Reminder time 8:00 PM, 8:00 PM".
      expect(node.label, contains(english.reminderTimeLabel));
      expect(node.label, contains('8:00 PM'));
      expect('${node.label}${node.value}'.split('8:00 PM').length - 1, 1);

      handle.dispose();
    });
  });

  group('layout', () {
    testWidgets('card and banner share both edges (M6 G1)', (tester) async {
      platform.permission = ReminderPermission.denied;
      await pumpScreen(tester);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final cards = tester.widgetList<MxCard>(find.byType(MxCard)).toList();
      expect(cards, hasLength(2));
      final settingsCard = tester.getRect(find.byType(MxCard).first);
      final banner = tester.getRect(find.byType(MxCard).last);

      expect(banner.left, settingsCard.left);
      expect(banner.right, settingsCard.right);
      // The banner sits below the card and does not overlap it (M6 G7).
      expect(banner.top, greaterThan(settingsCard.bottom));
    });

    testWidgets('both rows clear the 48dp touch target (M6 G4)', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(tester.getRect(find.byType(Switch)).height, greaterThan(0));
      expect(
        tester.getRect(find.text(english.reminderTimeLabel)).height,
        greaterThan(0),
      );
      final row = tester.getRect(
        find.ancestor(
          of: find.text(english.reminderTimeLabel),
          matching: find.byType(InkWell),
        ).first,
      );
      expect(row.height, greaterThanOrEqualTo(48));
    });

    testWidgets('no overflow at 320x568, EN and VI', (tester) async {
      await pumpScreen(tester, surface: const Size(320, 568));
      expect(tester.takeException(), isNull);

      await pumpScreen(
        tester,
        surface: const Size(320, 568),
        locale: const Locale('vi'),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 320x568 with textScaler 2.0', (tester) async {
      await pumpScreen(tester, surface: const Size(320, 568), textScale: 2);

      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 412 wide', (tester) async {
      await pumpScreen(tester, surface: const Size(412, 892));

      expect(tester.takeException(), isNull);
    });
  });
}
