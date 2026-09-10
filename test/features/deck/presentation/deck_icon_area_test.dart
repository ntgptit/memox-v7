import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_icon_area_widget.dart';
import 'package:memox/core/theme/extensions/app_ink.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';

/// The identity well's fill, and the glyph-on-well floor it must clear.
///
/// **Not a golden.** A pixel comparison would tell a reader a colour changed,
/// not what it was measured against or why. This pins the actual contract:
/// the well is `surfaceMuted` — no brand hue of its own — and the glyph reads
/// `AppInk.accent` (`primary`) directly against it. The well walked
/// `surfaceMuted`+`primary` (once, on an older palette, shelved on a report
/// reading 2.31:1 in dark) → `primaryContainer`+`onPrimaryContainer` (safe,
/// read as too pale) → a 25% blend (still too pale) → solid `primary`+
/// `onPrimary` (read as too loud) → the same fill eased 20%, then 40%, off
/// its own saturation → no fill, a `primary` border → back to
/// `surfaceMuted`+`primary`, chosen from a side-by-side of eight options.
///
/// **The first stop and the last stop are the same recipe** — what changed is
/// the palette underneath it, not the widget's choice. The 2.31:1 figure a
/// much older report recorded is not re-derived here; today's tokens are
/// measured directly, so a future palette regression is caught by this test
/// rather than by re-reading a doc that may already be stale again.
void main() {
  // sRGB relative luminance (WCAG 2.x definition).
  double gammaExpand(double channel) => channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

  double luminance(Color c) =>
      0.2126 * gammaExpand(c.r) +
      0.7152 * gammaExpand(c.g) +
      0.0722 * gammaExpand(c.b);

  double contrast(Color a, Color b) {
    final la = luminance(a), lb = luminance(b);
    final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  Future<(Color fill, Color glyphInk)> wellOf(
    WidgetTester tester,
    ThemeData theme,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Center(
            child: DeckIconArea(
              icon: Icons.folder_outlined,
              tint: AppInk.accent,
              semanticLabel: 'Deck',
            ),
          ),
        ),
      ),
    );

    final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final fill = (box.decoration as BoxDecoration).color!;
    final icon = tester.widget<Icon>(find.byType(Icon));
    return (fill, icon.color!);
  }

  group('the well is neutral, and the glyph carries the brand colour', () {
    for (final (name, theme) in <(String, ThemeData)>[
      ('light', buildLightTheme()),
      ('dark', buildDarkTheme()),
    ]) {
      testWidgets(name, (tester) async {
        final scheme = theme.colorScheme;
        final semantic = theme.extension<AppSemanticColors>()!;
        final (fill, glyph) = await wellOf(tester, theme);

        expect(
          fill,
          semantic.surfaceMuted,
          reason: 'the well carries no brand hue of its own',
        );
        expect(
          glyph,
          scheme.primary,
          reason:
              'AppInk.accent resolves to primary — the glyph is the well\'s '
              'only coloured mark',
        );
        expect(
          contrast(glyph, fill),
          greaterThanOrEqualTo(3),
          reason:
              'a glyph this large owes the same 3:1 floor a control edge '
              'does — an older palette missed it here at 2.31:1 in dark, '
              "which is the exact regression this assertion exists to catch "
              'if the palette ever drifts back',
        );
      });
    }
  });

  testWidgets(
    "the well's fill is not the Study button's, so one row does not repeat "
    'the same surface twice',
    (tester) async {
      // Both are now neutral-ish surfaces rather than brand fills, so the
      // repetition risk shifted from "same hue" to "same exact colour" — this
      // asserts they are not literally the same token, which would be the
      // failure mode a copy-paste produces.
      final theme = buildLightTheme();
      final semantic = theme.extension<AppSemanticColors>()!;

      expect(
        semantic.surfaceMuted,
        isNot(theme.colorScheme.secondaryContainer),
      );
    },
  );
}
