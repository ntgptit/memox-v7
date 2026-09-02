import 'package:flutter/material.dart';
import 'dart:ui' show CheckedState;

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/features/settings/domain/models/app_theme_mode_model.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../../../support/color_math.dart';
import '../domain/support/fake_app_settings_repository.dart';
import 'support/settings_widget_harness.dart';

/// What a screen reader and a tap target get from the Settings screen
/// (wireframe W6).
void main() {
  final english = AppLocalizationsEn();

  /// WCAG AA for body text.
  const double kAaBodyText = 4.5;

  group('guideline checks', () {
    testWidgets('meets the tap target and label guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSettings(tester, FakeAppSettingsRepository());

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });
  });

  group('contrast', () {
    // **Measured from the tokens, not from `textContrastGuideline`**, which is
    // the call `study_accessibility_test.dart` already made and recorded: that
    // guideline samples the rendered pixels of a semantics node, and on a 12px
    // line most glyph pixels are only partially covered. It reports 1.35:1 in
    // light on the pair below, which measures 7.0:1. A number nobody can see is
    // not a number to gate on.
    for (final brightness in Brightness.values) {
      testWidgets('every colour this screen writes text in passes AA in '
          '${brightness.name}', (tester) async {
        await pumpSettings(
          tester,
          FakeAppSettingsRepository(),
          brightness: brightness,
        );

        final element = tester.element(find.byType(SettingsScreen));
        final theme = Theme.of(element);
        final scheme = theme.colorScheme;
        final semantic = Theme.of(element).extension<AppSemanticColors>()!;

        // The two supporting lines: the BR-213 note and the reset scope
        // sentence. Both `onSurfaceVariant`, one on a card and one on the page,
        // and the two surfaces are a ladder step apart.
        expect(
          contrast(scheme.onSurfaceVariant, scheme.surface),
          greaterThanOrEqualTo(kAaBodyText),
        );
        // Group headings, field labels and every radio label.
        expect(
          contrast(scheme.onSurface, scheme.surface),
          greaterThanOrEqualTo(kAaBodyText),
        );
        // The error band, which is the one surface on this screen that is not
        // the page colour.
        expect(
          contrast(scheme.onErrorContainer, scheme.errorContainer),
          greaterThanOrEqualTo(kAaBodyText),
        );
        // **The band's Retry, and the pair that used to fail.** This asserted
        // the opposite until M100.18: the brand ink measured 3.72:1 on the
        // error band in dark (5.87:1 in light), which is why only dark had to
        // route the button away from it. Inverting the dark accent to tone 80
        // took it to 6.76:1, so the ground no longer forces the choice.
        //
        // Kept in the other direction rather than deleted, for the reason the
        // original was written: a palette that drifts back under the floor
        // must fail here rather than quietly re-introduce a fallback ink.
        expect(
          contrast(scheme.primary, scheme.errorContainer),
          greaterThanOrEqualTo(kAaBodyText),
          reason:
              'the brand ink fell back under AA on the error band, so the '
              "band's Retry is forced onto a fallback again",
        );
        // The reset action, which is `danger` as a label rather than a fill
        // (S5) — so it is held to the text floor, not to 3:1. Measured against
        // the **page**, which is where it sits; it is not on a card.
        expect(
          contrast(semantic.danger, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(kAaBodyText),
        );
      });
    }
  });

  group('roles and values', () {
    testWidgets('each choice row is announced as a radio with its selected '
        'state', (tester) async {
      // W6: the selected state must not rest on colour. The flag is what a
      // screen reader reads, and it is what proves the wiring rather than the
      // widget's reputation.
      final handle = tester.ensureSemantics();
      await pumpSettings(tester, FakeAppSettingsRepository());

      // **`getSemanticsData()`, not the node's own flags.** `RadioListTile` is
      // a merge boundary: the label and the tap sit on the boundary node while
      // the checked state sits on the control node inside it, and only the
      // merged data is what the platform — and therefore the user — receives.
      final selected = tester
          .getSemantics(find.byType(RadioListTile<AppThemeMode>).first)
          .getSemanticsData();
      final unselected = tester
          .getSemantics(find.byType(RadioListTile<AppThemeMode>).at(1))
          .getSemanticsData();

      // `CheckedState`, not a boolean: the engine distinguishes "checked",
      // "not checked" and "has no check state at all", and only the third
      // would mean the row never announced itself as a choice.
      expect(selected.flagsCollection.isChecked, CheckedState.isTrue);
      expect(unselected.flagsCollection.isChecked, CheckedState.isFalse);

      // The row itself is tappable and labelled, so the whole 48dp target —
      // not just the glyph — reaches the choice.
      expect(selected.label, english.settingsThemeSystem);
      expect(selected.hasAction(SemanticsAction.tap), isTrue);

      handle.dispose();
    });

    testWidgets('every group heading is in the semantics tree, which is what '
        'tells three rows labelled System apart', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSettings(tester, FakeAppSettingsRepository());

      for (final label in <String>[
        english.settingsStudyDefaultsSection,
        english.settingsAppearanceSection,
        english.settingsLanguageSection,
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }

      handle.dispose();
    });

    testWidgets('the error band is a live region, because nothing else '
        'announces it', (tester) async {
      // It appears while focus is still on the row the user just tapped, and
      // that row does not change — so without this a screen-reader user is told
      // nothing at all.
      final handle = tester.ensureSemantics();
      await pumpSettings(tester, FailingAppSettingsRepository());

      await tester.ensureVisible(find.text(english.settingsThemeDark));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.settingsThemeDark));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(Semantics),
          matching: find.text(english.settingsSaveErrorTitle),
        ),
        findsWidgets,
      );
      expect(
        tester
            .widgetList<Semantics>(find.byType(Semantics))
            .any((widget) => widget.properties.liveRegion ?? false),
        isTrue,
      );

      handle.dispose();
    });
  });
}
