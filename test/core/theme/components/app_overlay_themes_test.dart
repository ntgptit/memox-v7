import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_elevation.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';

import '../../../support/color_math.dart';

/// The paint Material used to choose for us.
///
/// **Why this is a value test and not a render audit.** The first attempt pointed
/// the strict visual auditor at an open bottom sheet, and it reported six
/// blocking contrast failures — all of them text *underneath* the barrier, which
/// is dimmed on purpose. That is the auditor working correctly on a subject it
/// was not built for: it walks a screen at rest and judges everything it paints,
/// and half of an overlay's render tree is content the user is deliberately being
/// stopped from reading. Making it pass would have taken a large allowance list
/// asserting that unreadable text is fine, which is the opposite of what these
/// allowances are for.
///
/// So the overlay tokens are checked where they are decided — in the theme — and
/// what they look like on screen stays with the goldens that already cover the
/// dialog and the sheet.
void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
  };

  group('the modal barrier', () {
    test('is derived from scrim, not from Material grey', () {
      // Material's default is `Colors.black54`: no hue, identical in both modes.
      // It survived a full colour audit because a source scan cannot see a
      // colour that exists only as a framework default — which is the entire
      // reason this file exists.
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;
        final dialog = entry.value.dialogTheme.barrierColor;
        final sheet = entry.value.bottomSheetTheme.modalBarrierColor;

        for (final barrier in <String, Color?>{
          'dialog': dialog,
          'sheet': sheet,
        }.entries) {
          expect(
            barrier.value,
            isNotNull,
            reason:
                '${entry.key} ${barrier.key}: unset, so Material paints '
                'black54 — a flat grey over a navy palette',
          );
          expect(
            barrier.value!.r,
            closeTo(scheme.scrim.r, 0.001),
            reason:
                '${entry.key} ${barrier.key} must come from the scrim token',
          );
          expect(barrier.value!.a, lessThan(1.0));
        }
      }
    });

    test('is the handoff scrim, 45% in both modes', () {
      // **Until M100.93 this asserted dark hides more than light** (48% and
      // 72%). The handoff Scrim is the `scrim` role at 45% in both modes, and
      // the dark page's own depth is the surface ladder's, not the barrier's.
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;
        final expected = scheme.scrim.withValues(alpha: 0.45);

        expect(entry.value.dialogTheme.barrierColor, expected);
        expect(entry.value.bottomSheetTheme.modalBarrierColor, expected);
      }
    });
  });

  group('the dialog (handoff Dialog, M100.93)', () {
    test('radius 20, no edge, raised with the Material shadow (D19)', () {
      for (final entry in themes.entries) {
        final dialog = entry.value.dialogTheme;
        final shape = dialog.shape! as RoundedRectangleBorder;

        expect(shape.borderRadius, BorderRadius.circular(AppRadius.card));
        expect(shape.side, BorderSide.none, reason: entry.key);
        expect(dialog.elevation, AppElevation.raised, reason: entry.key);
        expect(
          dialog.shadowColor,
          materialShadowColor(entry.value.colorScheme),
          reason: entry.key,
        );
      }
    });
  });

  group('the tooltip', () {
    test('is legible, and is the same slate in both modes', () {
      for (final entry in themes.entries) {
        final tooltip = entry.value.tooltipTheme;
        final decoration = tooltip.decoration! as BoxDecoration;
        final label = tooltip.textStyle!.color!;

        expect(
          contrast(label, decoration.color!),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}: a tooltip is small text and gets no exemption',
        );
      }

      // **The slate does not flip, by the handoff's design** (M100.87). Its
      // `inverseSurface` is one value in both themes — a snackbar and a
      // tooltip are the same `#34395D` in light and dark — so this pins the
      // sameness rather than the inversion it used to ask for.
      expect(
        (themes['light']!.tooltipTheme.decoration! as BoxDecoration).color,
        (themes['dark']!.tooltipTheme.decoration! as BoxDecoration).color,
      );
    });
  });

  group('the rest of what Material would have chosen', () {
    test('every overlay token is claimed in both modes', () {
      for (final entry in themes.entries) {
        final theme = entry.value;
        final semantic = theme.extension<AppSemanticColors>()!;

        expect(theme.progressIndicatorTheme.color, theme.colorScheme.primary);
        expect(theme.textSelectionTheme.cursorColor, theme.colorScheme.primary);
        expect(theme.textSelectionTheme.selectionHandleColor, isNotNull);
        expect(theme.dividerTheme.color, semantic.borderSubtle);
        expect(theme.scrollbarTheme.thumbColor, isNotNull);
      }
    });

    test('a spinner reads against the surface it spins on', () {
      for (final entry in themes.entries) {
        final theme = entry.value;

        expect(
          contrast(
            theme.progressIndicatorTheme.color!,
            theme.colorScheme.surface,
          ),
          greaterThanOrEqualTo(3.0),
          reason:
              '${entry.key}: a spinner is a graphic and needs the non-text '
              'floor at minimum',
        );
      }
    });
  });
}
