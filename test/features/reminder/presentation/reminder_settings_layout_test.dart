import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminder/domain/models/reminder_capability_model.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../support/fake_reminder_platform.dart';
import '../support/reminder_screen_harness.dart';
import 'package:flutter/rendering.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/reminder/presentation/widgets/sections/reminder_banner_section_widget.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// The M6 geometry contract (G1, G4, G5, G7), measured with `getRect` and
/// `didExceedMaxLines` rather than asserted by eye.
///
/// The behavioural half is `reminder_settings_screen_test.dart`; how the screen
/// is announced is `reminder_settings_a11y_test.dart`.
void main() {
  final english = AppLocalizationsEn();

  late ReminderScreenHarness harness;

  setUp(() => harness = ReminderScreenHarness());

  group('layout', () {
    testWidgets('card and banner share both edges (M6 G1)', (tester) async {
      harness.platform.permission = ReminderPermission.denied;
      await harness.pump(tester);
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
      harness.platform = FakeReminderPlatform(permissionGate: gate)
        ..shouldFailSchedule = shouldFailSchedule;
      await harness.pump(tester);

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
      await harness.pump(tester);

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
      await harness.pump(tester, surface: const Size(320, 568));
      expect(tester.takeException(), isNull);

      await harness.pump(
        tester,
        surface: const Size(320, 568),
        locale: const Locale('vi'),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 320x568 with textScaler 2.0', (tester) async {
      await harness.pump(tester, surface: const Size(320, 568), textScale: 2);

      expect(tester.takeException(), isNull);
    });

    testWidgets('the banner fits too, at 320x568 with textScaler 2.0, EN and '
        'VI', (tester) async {
      // **G7 and A2 are each tested, and were never tested together.** The
      // overflow checks above all run against a harness.platform that grants and
      // schedules, so the banner is never on screen for them; the banner test
      // runs at 393x852 and scale 1. Card plus banner plus two paragraphs at
      // the narrowest width and the largest scale is the one combination most
      // likely to overflow, and it was the one nothing rendered.
      for (final locale in <Locale>[const Locale('en'), const Locale('vi')]) {
        harness.platform = FakeReminderPlatform(
          permission: ReminderPermission.denied,
        );
        await harness.pump(
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
      harness.platform = FakeReminderPlatform(
        permission: ReminderPermission.denied,
      );
      await harness.pump(tester);
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

      // The gap, measured rather than assumed. The commit that added this test
      // said it held the gap and it did not, which is the same shape of claim
      // the test itself exists to stop.
      //
      // The button's *box* top against the message bottom: `MxTextButton`
      // carries a 48dp height floor with its own vertical padding, so the
      // distance to the painted label is not the spacer — the box moves one for
      // one with it and by nothing else.
      final Rect messageRect = tester.getRect(
        find
            .descendant(
              of: find.byType(ReminderBannerSectionWidget),
              matching: find.byType(Text),
            )
            .at(1),
      );
      expect(
        retry.top - messageRect.bottom,
        closeTo(AppSpacing.xs, 0.5),
        reason: 'the Settings band puts xs here, not sm',
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
      harness.platform = FakeReminderPlatform(
        permission: ReminderPermission.denied,
      );
      await harness.pump(tester);
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

    testWidgets('the hardest configuration the wireframe names, in dark', (
      tester,
    ) async {
      // 320dp, scale 2.0, Vietnamese, dark — the combination M6 A1/A2 name and
      // that no test ran end to end. Brightness changes colour tokens and not
      // text metrics, so a light-theme geometry pass *should* hold here; the
      // point is that "should" was the only thing holding it, and the banner is
      // present, which none of the other scale-2 cases arrange.
      harness.platform = FakeReminderPlatform(
        permission: ReminderPermission.denied,
      );
      await harness.pump(
        tester,
        surface: const Size(320, 568),
        textScale: 2,
        locale: const Locale('vi'),
        brightness: Brightness.dark,
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.byType(MxCard), findsNWidgets(2));
      expect(tester.takeException(), isNull);

      // The same `didExceedMaxLines` sweep the light-theme case uses, and for
      // the same reason: a label that runs out of room is cut silently, with
      // no overflow stripe and no exception for `takeException` to catch.
      final truncated = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .where((paragraph) => paragraph.didExceedMaxLines)
          .map((paragraph) => paragraph.text.toPlainText())
          .toList();

      expect(truncated, isEmpty, reason: 'ellipsized in vi/dark at 320@2.0');
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
        await harness.pump(
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
      await harness.pump(tester, surface: const Size(412, 892));

      expect(tester.takeException(), isNull);
    });
  });
}
