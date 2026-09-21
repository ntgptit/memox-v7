import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/settings/domain/models/app_theme_mode_model.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/features/settings/presentation/widgets/sections/settings_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:memox/l10n/generated/app_localizations_vi.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_feedback_band.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_tap_target.dart';

import '../domain/support/fake_app_settings_repository.dart';
import 'support/settings_widget_harness.dart';

/// The geometry contract of the Settings screen (wireframe W5) and its
/// accessibility floor (W6).
///
/// **Measured with `getRect` on the widgets a reader actually sees**, never on
/// the invisible box containing them: a `Column` that spans the screen would
/// satisfy every alignment claim while the cards inside it were four pixels
/// out of line. A golden cannot make these claims either — it compares the
/// screen with yesterday's picture of itself, so a wrong-but-stable edge passes
/// forever.
void main() {
  final english = AppLocalizationsEn();
  final vietnamese = AppLocalizationsVi();

  List<Rect> cardRects(WidgetTester tester) => tester
      .widgetList<MxCard>(find.byType(MxCard))
      .map((card) => tester.getRect(find.byWidget(card)))
      .toList();

  /// The heading's painted rect. The label is uppercased on screen (D18) while
  /// its accessible name stays as written, so the finder has to ask for the
  /// painted form.
  Rect sectionHeading(WidgetTester tester, String label) =>
      tester.getRect(find.text(label.toUpperCase()));

  Finder traySurface<T>() => find.descendant(
    of: find.byWidgetPredicate((widget) => widget is MxSegmentedTray<T>),
    matching: find.byKey(MxSegmentedTray.surfaceKey),
  );

  group('one column', () {
    testWidgets('the five group cards share both x edges', (tester) async {
      // Not a natural consequence: one card wrapped in an extra `Padding` is
      // enough to break it, and four pixels between cards twenty-four apart is
      // invisible to the eye.
      //
      // Five since M100.51: study defaults, appearance, language, the row that
      // opens the daily reminder, and the row that opens the licences. The
      // count is asserted rather than implied — a card that stops rendering
      // would otherwise leave the remaining ones sharing their edges, and this
      // test would agree.
      await pumpSettings(tester, FakeAppSettingsRepository());

      final rects = cardRects(tester);

      expect(rects, hasLength(5));
      expect(rects.map((rect) => rect.left).toSet(), hasLength(1));
      expect(rects.map((rect) => rect.right).toSet(), hasLength(1));
    });

    testWidgets('every group heading starts at the same x as its card', (
      tester,
    ) async {
      await pumpSettings(tester, FakeAppSettingsRepository());

      final left = cardRects(tester).first.left;

      for (final label in <String>[
        english.settingsStudyDefaultsSection,
        english.settingsAppearanceSection,
        english.settingsLanguageSection,
      ]) {
        expect(sectionHeading(tester, label).left, left);
      }
    });

    testWidgets('the reset action and its sentence share that x too', (
      tester,
    ) async {
      // **Both, not just the sentence.** The action is measured at the button,
      // not at its label: the button carries a leading `restart_alt` glyph, so
      // the *text* starts one icon-plus-gap in while the thing a reader sees
      // begin the column is the glyph. Measuring the label would have asserted
      // 36 against 16 and read as a misalignment that is not one.
      await pumpSettings(tester, FakeAppSettingsRepository());
      await tester.ensureVisible(find.text(english.settingsResetDescription));
      await tester.pumpAndSettle();

      final left = cardRects(tester).first.left;

      expect(
        tester.getRect(find.text(english.settingsResetDescription)).left,
        left,
      );
      expect(
        tester
            .getRect(
              find.ancestor(
                of: find.text(english.settingsResetAction),
                matching: find.byType(TextButton),
              ),
            )
            .left,
        left,
      );
    });

    testWidgets('the theme tray lines up with the study card\'s own content', (
      tester,
    ) async {
      // W5: the choice cards carry only vertical padding so each row's target
      // spans the card, and every row supplies the horizontal gutter itself.
      // The measurable consequence is that a radio row's left edge equals the
      // left edge of the label inside the Study defaults card.
      await pumpSettings(tester, FakeAppSettingsRepository());

      // **The field, not its label.** The label used to be a standalone `Text`
      // at the card's content edge; it is now `InputDecoration.labelText`,
      // which floats inside the field's own inset. The field's left edge is
      // what "the card's own content edge" means, and it is what the radio
      // rows below have to agree with.
      final labelLeft = tester.getRect(find.byType(MxTextField).first).left;
      // Typed on `AppThemeMode`, because `System` is the label of a theme row
      // *and* of a language row — the same ambiguity a screen-reader user hears
      // and the reason W6 requires the group heading in the semantics tree.
      final rowLeft = tester.getRect(traySurface<AppThemeMode>()).left;

      expect(rowLeft, labelLeft);
    });

    testWidgets('the new-card-order tray starts on the study card\'s own '
        'content edge', (tester) async {
      // The other half of W5's column rule: this group's card already pads its
      // content, so its rows carry `contentPadding: zero` and land exactly on
      // the label above them. The two choice cards get to the same x from the
      // opposite direction.
      await pumpSettings(tester, FakeAppSettingsRepository());

      // **The field, not its label.** The label used to be a standalone `Text`
      // at the card's content edge; it is now `InputDecoration.labelText`,
      // which floats inside the field's own inset. The field's left edge is
      // what "the card's own content edge" means, and it is what the radio
      // rows below have to agree with.
      final labelLeft = tester.getRect(find.byType(MxTextField).first).left;
      final orderRowLeft = tester.getRect(traySurface<NewCardOrder>()).left;

      expect(orderRowLeft, labelLeft);
    });
  });

  group('vertical rhythm', () {
    testWidgets('each heading sits headingGap above its card', (tester) async {
      await pumpSettings(tester, FakeAppSettingsRepository());

      final cards = cardRects(tester);
      final heading = sectionHeading(
        tester,
        english.settingsStudyDefaultsSection,
      );

      expect(
        cards.first.top - heading.bottom,
        closeTo(SettingsSectionWidget.headingGap, 0.5),
      );
    });

    testWidgets('the gap between one card and the next heading is the '
        'section gap, for every pair', (tester) async {
      // Both pairs, not one. They share `SettingsScreen.sectionGap` today, so
      // one assertion would look sufficient — and would stay green the day
      // somebody wraps the Language group in a `Padding` of its own.
      await pumpSettings(tester, FakeAppSettingsRepository());

      final cards = cardRects(tester);

      expect(
        sectionHeading(tester, english.settingsAppearanceSection).top -
            cards[0].bottom,
        closeTo(SettingsScreen.sectionGap, 0.5),
      );
      expect(
        sectionHeading(tester, english.settingsLanguageSection).top -
            cards[1].bottom,
        closeTo(SettingsScreen.sectionGap, 0.5),
      );
      // The third pair has no heading to anchor on — the daily-reminder row is
      // the one card here whose label is its own heading — so it is measured
      // card to card. Left out, the one `SizedBox` nothing else covers would
      // be free to change.
      expect(
        cards[3].top - cards[2].bottom,
        closeTo(SettingsScreen.sectionGap, 0.5),
      );
    });

    testWidgets('the last card sits a section gap above the reset action', (
      tester,
    ) async {
      await pumpSettings(tester, FakeAppSettingsRepository());
      await tester.ensureVisible(find.text(english.settingsResetAction));
      await tester.pumpAndSettle();

      final cards = cardRects(tester);
      // The button, not its label: the label is centred inside a 48dp target,
      // so measuring it would silently absorb any change to the button height.
      final action = tester.getRect(
        find.ancestor(
          of: find.text(english.settingsResetAction),
          matching: find.byType(TextButton),
        ),
      );

      expect(
        action.top - cards.last.bottom,
        closeTo(SettingsScreen.sectionGap, 0.5),
      );
    });
  });

  group('touch targets', () {
    testWidgets('each remaining radio row and segmented tray clears 48dp', (
      tester,
    ) async {
      await pumpSettings(tester, FakeAppSettingsRepository());

      final rows = find.byWidgetPredicate((widget) => widget is RadioListTile);

      expect(rows, findsNWidgets(3));
      for (var i = 0; i < 3; i++) {
        expect(
          tester.getRect(rows.at(i)).height,
          greaterThanOrEqualTo(AppSizing.touchTarget),
        );
      }
      final trays = find.descendant(
        of: find.byWidgetPredicate((widget) => widget is MxSegmentedTray),
        matching: find.byType(MxTapTarget),
      );
      expect(trays, findsNWidgets(5));
      for (var i = 0; i < 5; i++) {
        expect(
          tester.getRect(trays.at(i)).height,
          greaterThanOrEqualTo(AppSizing.touchTarget),
        );
      }
    });
  });

  group('320dp at textScaler 2.0', () {
    testWidgets('the cards still share both x edges in Vietnamese', (
      tester,
    ) async {
      // The tightest combination the wireframe names, and the one where a
      // layout that only *looks* aligned at 390 comes apart.
      await pumpSettings(
        tester,
        FakeAppSettingsRepository(),
        locale: const Locale('vi'),
        surface: const Size(320, 568),
        textScale: 2,
      );

      final rects = cardRects(tester);

      expect(rects.map((rect) => rect.left).toSet(), hasLength(1));
      expect(rects.map((rect) => rect.right).toSet(), hasLength(1));
      // Two, not one: `Theo hệ thống` labels a theme row and a language row.
      expect(find.text(vietnamese.settingsThemeSystem), findsNWidgets(2));
    });

    testWidgets('all four cards still start their interior column on one x', (
      tester,
    ) async {
      // The compact half of the '390' claim above, and the tier that claim
      // cannot see. Below 360dp the screen gutter used to step to `md`, and
      // the choice rows and the reminder row stepped with it — the Study
      // defaults card took `MxCardPadding.standard`'s fixed 16 and did not,
      // so four cards sharing their outer edges held their content at three
      // different x positions (W5).
      //
      // **`md` is now `lg` (GC-7, 2026-09-17).** The screen gutter is `lg`
      // at every width, and `applyCompactScale` no longer overrides
      // `listTileTheme.contentPadding`, so the rows no longer step down
      // below 360dp either — all four still agree, just one gutter step
      // wider than before.
      await pumpSettings(
        tester,
        FakeAppSettingsRepository(),
        surface: const Size(320, 568),
        textScale: 2,
      );

      final cardLeft = cardRects(tester).first.left;
      final content = cardLeft + AppSpacing.lg;

      // Study defaults: the field is the card's own content edge.
      expect(tester.getRect(find.byType(MxTextField).first).left, content);
      // At this scale neither two-choice tray fits. The caller explicitly
      // falls back to option rows rather than truncating a label.
      expect(
        find.byWidgetPredicate((widget) => widget is MxSegmentedTray),
        findsNothing,
      );
      // The reminder row's gutter comes from `applyCompactScale`'s
      // `listTileTheme.contentPadding`, which is the value the other three
      // now agree with.
      expect(
        tester.getRect(find.byIcon(Icons.notifications_outlined)).left,
        content,
      );
    });

    testWidgets('a failing save puts its band on the rows it reports on', (
      tester,
    ) async {
      // The band restated `AppSpacing.lg` while the rows above it took the
      // screen gutter, so below 360dp it was inset 4dp further than the thing
      // it was explaining — in the one state where the user is reading
      // carefully.
      //
      // Both now agree at `lg` (GC-7, 2026-09-17): the screen gutter no
      // longer steps down below 360dp, so the band's own `lg` and the row's
      // content edge land on the same x by construction rather than by luck.
      await pumpSettings(
        tester,
        FailingAppSettingsRepository(),
        surface: const Size(320, 568),
        textScale: 2,
      );

      await tester.ensureVisible(find.text(english.settingsThemeDark));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.settingsThemeDark));
      await tester.pumpAndSettle();

      final rowContentLeft = cardRects(tester)[1].left + AppSpacing.lg;

      expect(tester.getRect(find.byType(MxFeedbackBand)).left, rowContentLeft);
    });

    testWidgets('the last row is reachable by scrolling', (tester) async {
      // W5's bottom-nav clearance, expressed as something a host test can
      // check: the final band must be scrollable into view rather than clipped.
      await pumpSettings(
        tester,
        FakeAppSettingsRepository(),
        locale: const Locale('vi'),
        surface: const Size(320, 568),
        textScale: 2,
      );

      await tester.ensureVisible(
        find.text(vietnamese.settingsResetDescription),
      );
      await tester.pumpAndSettle();

      expect(find.text(vietnamese.settingsResetDescription), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
