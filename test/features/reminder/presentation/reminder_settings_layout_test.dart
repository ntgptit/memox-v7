import 'dart:async';
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
import 'package:memox/features/reminder/presentation/widgets/sections/reminder_banner_section_widget.dart';
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

    /// The card's height across a write, measured rather than reasoned about.
    ///
    /// G5 holds today because nothing inside the card renders or hides on
    /// `isBusy` — but that is a property of the current widget tree, not of the
    /// contract, and the first spinner someone puts beside a locked control
    /// makes the card grow by however tall it is. A card that changes height
    /// mid-write drags the banner and everything under it.
    ///
    /// **The permission request is held open.** Otherwise every command this
    /// fake serves resolves on the same microtask as the tap: the first
    /// `pump()` already shows the settled state, all three measurements are one
    /// frame, and the test passes against a card deliberately grown by 120dp.
    /// Both cases below are mutation-checked against exactly that.
    Future<void> expectStableHeight(
      WidgetTester tester, {
      required bool shouldFailSchedule,
    }) async {
      final gate = Completer<ReminderPermission>();
      platform = FakeReminderPlatform(permissionGate: gate)
        ..shouldFailSchedule = shouldFailSchedule;
      await pumpScreen(tester);

      double cardHeight() => tester.getRect(find.byType(MxCard).first).height;

      final atRest = cardHeight();

      await tester.tap(find.byType(Switch));
      await tester.pump();
      final whileSubmitting = cardHeight();

      gate.complete(ReminderPermission.granted);
      await tester.pumpAndSettle();
      final afterSettling = cardHeight();

      expect(whileSubmitting, closeTo(atRest, 0.5));
      expect(afterSettling, closeTo(atRest, 0.5));
    }

    testWidgets('the card keeps its height from S2 through S3 to S4 (M6 G5)', (
      tester,
    ) async {
      // The success path: off, enabling, on. Named for the states it reaches —
      // an earlier version of this test claimed S4 and drove the schedule to
      // failure instead, so the one transition a user takes every time was the
      // one it never measured.
      await expectStableHeight(tester, shouldFailSchedule: false);
      expect(find.byType(MxCard), findsOneWidget, reason: 'S4 shows no banner');
    });

    testWidgets('the card keeps its height from S2 through S3 to S8 (M6 G5)', (
      tester,
    ) async {
      // The failure path: the banner appears *below* the card, and G7 says it
      // pushes what follows down rather than resizing what precedes it.
      await expectStableHeight(tester, shouldFailSchedule: true);
      expect(find.byType(MxCard), findsNWidgets(2), reason: 'S8 adds a banner');
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

    testWidgets('the banner fits too, at 320x568 with textScaler 2.0, EN and '
        'VI', (tester) async {
      // **G7 and A2 are each tested, and were never tested together.** The
      // overflow checks above all run against a platform that grants and
      // schedules, so the banner is never on screen for them; the banner test
      // runs at 393x852 and scale 1. Card plus banner plus two paragraphs at
      // the narrowest width and the largest scale is the one combination most
      // likely to overflow, and it was the one nothing rendered.
      for (final locale in <Locale>[const Locale('en'), const Locale('vi')]) {
        platform = FakeReminderPlatform(permission: ReminderPermission.denied);
        await pumpScreen(
          tester,
          surface: const Size(320, 568),
          textScale: 2,
          locale: locale,
        );
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(find.byType(MxCard), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the banner speaks the same grammar as the Settings band', (
      tester,
    ) async {
      // **Every property here was claimed unified once and was not.** Three of
      // four replacements silently matched nothing, and no test noticed —
      // `reminder_settings_layout_test` pinned the card edges, the overflow,
      // the ellipsis and the retry ink, and none of those move when the
      // message style, the gap or the alignment does. So they are pinned here,
      // each against the value the sibling band uses, not against a literal.
      platform = FakeReminderPlatform(permission: ReminderPermission.denied);
      await pumpScreen(tester);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final BuildContext bannerContext = tester.element(
        find.byType(ReminderBannerSectionWidget),
      );

      // `.at(1)`, not `.last`: the band holds title, message and the retry
      // button's own label, and `.last` picked the button — `labelLarge` at 14,
      // which made this test agree with itself whatever the message did.
      final Text message = tester.widget<Text>(
        find
            .descendant(
              of: find.byType(ReminderBannerSectionWidget),
              matching: find.byType(Text),
            )
            .at(1),
      );
      expect(
        message.style?.fontSize,
        Theme.of(bannerContext).textTheme.bodySmall?.fontSize,
      );

      // Left, not right. Measured against the card rather than the screen: the
      // band is inset, so a button "on the left of the screen" would pass on a
      // band that had drifted right inside it.
      final Rect banner = tester.getRect(find.byType(MxCard).last);
      final Rect retry = tester.getRect(
        find.descendant(
          of: find.byType(ReminderBannerSectionWidget),
          matching: find.byType(TextButton),
        ),
      );
      expect(
        retry.left - banner.left,
        lessThan(banner.right - retry.right),
        reason:
            'Retry sits at the leading edge, as it does on the Settings band',
      );
    });

    testWidgets('the banner Retry reads its ink from the surface it sits on', (
      tester,
    ) async {
      // **The resolved foreground, not the token pair.** Asserting
      // `onErrorContainer` against `errorContainer` stays green if the accent
      // is dropped, because the band's *text* uses that pair either way — and
      // the default `primaryAccent` measures 3.72:1 here in dark, under the 4.5
      // its 14px w600 label needs. The golden harness renders only the resting
      // state, so nothing else on this screen would have caught it.
      platform = FakeReminderPlatform(permission: ReminderPermission.denied);
      await pumpScreen(tester);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final BuildContext bannerContext = tester.element(
        find.byType(ReminderBannerSectionWidget),
      );
      final ButtonStyle? style = tester
          .widget<TextButton>(
            find.descendant(
              of: find.byType(ReminderBannerSectionWidget),
              matching: find.byType(TextButton),
            ),
          )
          .style;

      expect(
        style?.foregroundColor?.resolve(<WidgetState>{}),
        Theme.of(bannerContext).colorScheme.onErrorContainer,
      );
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
