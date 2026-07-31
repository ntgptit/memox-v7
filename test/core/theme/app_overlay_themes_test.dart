import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../support/color_math.dart';

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

    test('hides more in dark than in light', () {
      // Not symmetry for its own sake. A 48% wash over `#F4F5F8` reads as a
      // dimmed page; the same wash over `#0A082D` is nearly invisible, because
      // the page is already almost as dark as the scrim.
      final light = themes['light']!.dialogTheme.barrierColor!;
      final dark = themes['dark']!.dialogTheme.barrierColor!;

      expect(dark.a, greaterThan(light.a));
    });
  });

  group('the tooltip', () {
    test('is legible, and inverts with the mode', () {
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

      // The two modes must not paint the same box: a tooltip that stayed dark in
      // dark mode is a black square on a navy page.
      expect(
        (themes['light']!.tooltipTheme.decoration! as BoxDecoration).color,
        isNot(
          (themes['dark']!.tooltipTheme.decoration! as BoxDecoration).color,
        ),
      );
    });
  });

  group('the rest of what Material would have chosen', () {
    test('every overlay token is claimed in both modes', () {
      for (final entry in themes.entries) {
        final theme = entry.value;
        final semantic = theme.extension<AppSemanticColors>()!;

        expect(theme.progressIndicatorTheme.color, semantic.focusRing);
        expect(theme.textSelectionTheme.cursorColor, semantic.focusRing);
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
