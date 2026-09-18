import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/components/overlays/app_backdrop_recipe.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/schemes/app_color_scheme.dart';
import 'package:memox/core/theme/app_theme.dart';

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

    test('is exactly 0.45 in both themes, from the one shared recipe', () {
      // **Used to be asymmetric — 0.48 light / 0.72 dark** — on the argument
      // that a wash over the near-black `#0A082D` page needed to go deeper
      // than the same wash over `#F4F5F8` to read as dimmed at all. v3 states
      // one value instead (§15.1: Scrim, Dialog and BottomSheet are all given
      // 0.45), so this is no longer a per-mode judgement call — it is one
      // recipe applied twice.
      expect(modalBarrierColor(lightColorScheme).toARGB32(), 0x730A0E27);
      expect(modalBarrierColor(darkColorScheme).toARGB32(), 0x73000000);
      expect(modalBarrierColor(lightColorScheme).r, lightColorScheme.scrim.r);
    });
  });

  group('the tooltip', () {
    test('is legible in both modes', () {
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

      // v3 (colors_and_type.css, 2026-09-17) gives `inverseSurface` the same
      // literal (`#34395D`) in both modes — like a `*Fixed` role, it no longer
      // inverts with brightness, so the box the tooltip paints is now the same
      // one in light and dark. Legibility (above) is what still has to hold.
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
