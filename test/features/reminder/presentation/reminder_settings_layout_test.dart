import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:memox/features/reminder/presentation/screens/reminder_settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../support/fake_reminder_platform.dart';

/// What the reminder screen looks like, and how it is announced.
///
/// The behavioural half is `reminder_settings_screen_test.dart`; this one holds
/// the M6 geometry contract (G1, G4, G7) and the A-items, which are measured
/// with `getRect`, `didExceedMaxLines` and the semantics tree rather than
/// asserted by eye.
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
        find
            .ancestor(
              of: find.text(english.reminderTimeLabel),
              matching: find.byType(InkWell),
            )
            .first,
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

    testWidgets('no label is ellipsized at 320x568 with textScaler 2.0', (
      tester,
    ) async {
      // **`didExceedMaxLines`, not `takeException`** (M6 A2). A label that runs
      // out of room is *cut*, silently — no overflow stripe, no exception — so
      // the four tests above would stay green while the row read
      // "Reminder…". That is exactly what happened while the time sat in the
      // trailing slot: 90dp of box for 422dp of intrinsic width.
      for (final locale in <Locale>[const Locale('en'), const Locale('vi')]) {
        await pumpScreen(
          tester,
          surface: const Size(320, 568),
          textScale: 2,
          locale: locale,
        );

        final truncated = tester
            .renderObjectList<RenderParagraph>(find.byType(RichText))
            .where((paragraph) => paragraph.didExceedMaxLines)
            .map((paragraph) => paragraph.text.toPlainText())
            .toList();

        expect(truncated, isEmpty, reason: 'ellipsized in $locale');
      }
    });

    testWidgets('no overflow at 412 wide', (tester) async {
      await pumpScreen(tester, surface: const Size(412, 892));

      expect(tester.takeException(), isNull);
    });
  });
}
