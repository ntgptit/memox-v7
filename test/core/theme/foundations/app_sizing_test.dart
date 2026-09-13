import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';

/// The dimensions a control *is*, and the two rules that keep them honest.
///
/// **A sizing token is only worth having if something renders it.** `AppSizing`
/// holds three values and no ladder, deliberately — the usual 32/40/48/56/64
/// control scale would put three rungs in the file that no screen draws. So the
/// invariant here is not "the scale climbs"; it is that each value is on the
/// grid, that the two heights stay in the order that makes `compact` compact,
/// and that the theme actually resolves them.
void main() {
  group('the values', () {
    test('the status dot is a mark, not a control', () {
      // It has no touch target because it is never touched. Stating that here
      // is what stops the next reader assuming the 48dp floor was forgotten —
      // and what would fail if someone made it tappable without moving it out
      // of this bracket.
      expect(AppSizing.statusDot, lessThan(AppSizing.controlDense));
    });

    test('every control dimension sits on the 4dp grid', () {
      // Structural geometry follows the 4dp rhythm; stroke, type size and
      // opacity have scales of their own and are not covered by this rule.
      for (final (String name, double value) in <(String, double)>[
        ('touchTarget', AppSizing.touchTarget),
        ('buttonCompact', AppSizing.buttonCompact),
        ('fab', AppSizing.fab),
        ('buttonMinWidth', AppSizing.buttonMinWidth),
        // Not a control, and on the grid all the same: the rhythm is what
        // keeps a mark aligned with the text it sits beside.
        ('statusDot', AppSizing.statusDot),
        // Painted marks too: the handoff IconTile's three extents.
        ('iconTileSm', AppSizing.iconTileSm),
        ('iconTileMd', AppSizing.iconTileMd),
        ('iconTileLg', AppSizing.iconTileLg),
        // Where a row divider starts past the leading column.
        ('listDividerIndent', AppSizing.listDividerIndent),
        // A painted mark: the handoff MasteryRing.
        ('masteryRing', AppSizing.masteryRing),
        // The handoff field: 52 single-line, 40 multi-line.
        ('input', AppSizing.input),
        ('inputMultilineMin', AppSizing.inputMultilineMin),
      ]) {
        expect(
          value % 4,
          0,
          reason: '$name is $value, which is off the 4dp grid',
        );
      }
    });

    test(
      'the reading row sits on the touch floor, and the theme states it',
      () {
        // The handoff ListRow: 48 MINIMUM, growing with its content (M100.91).
        // It was 56 — Material's `_defaultTileHeight` — from M100.36 4J until
        // the kit's list row replaced it. Owned here rather than left to
        // Flutter, and put on the theme so every ListTile reads it.
        expect(
          AppSizing.rowMinHeight,
          greaterThanOrEqualTo(AppSizing.touchTarget),
        );
        expect(AppSizing.rowMinHeight, 48);
        for (final build in <ThemeData Function()>[
          buildLightTheme,
          buildDarkTheme,
        ]) {
          expect(build().listTileTheme.minTileHeight, AppSizing.rowMinHeight);
        }
      },
    );

    test('the compact body is smaller than the target it keeps', () {
      // The whole point of the compact tier: the body comes down, the finger's
      // floor does not. If these ever met, `MaterialTapTargetSize.padded` would
      // be doing nothing and the tier would be a second name for `standard`.
      expect(AppSizing.buttonCompact, lessThan(AppSizing.touchTarget));
    });

    test('the FAB clearance is derived from the FAB, not repeated', () {
      // `AppSpacing.fabScrollClearance` is the button plus a gap on each side.
      // Written as arithmetic over the token rather than as a fourth literal,
      // so a FAB that ever changed size could not leave the clearance behind.
      expect(
        AppSpacing.fabScrollClearance,
        AppSizing.fab + AppSpacing.lg + AppSpacing.xxxl,
      );
    });
  });

  group('what the theme resolves', () {
    for (final (String mode, ThemeData Function() build)
        in <(String, ThemeData Function())>[
          ('light', buildLightTheme),
          ('dark', buildDarkTheme),
        ]) {
      test('$mode: a button cannot be built below the target', () {
        // Stated in the shared style rather than per component, so no screen
        // can pass a smaller one — there is no parameter to pass.
        final Size? minimum = build().filledButtonTheme.style?.minimumSize
            ?.resolve(const <WidgetState>{});

        expect(minimum, isNotNull, reason: 'the button states no minimum size');
        expect(minimum!.height, AppSizing.touchTarget);
        expect(minimum.width, AppSizing.buttonMinWidth);
      });

      test('$mode: an icon button cannot be built below the target', () {
        // The handoff IconButton paints a 36 ink circle (M100.90); the target
        // is what `MaterialTapTargetSize.padded` restores around it, so the
        // contract is the pair — never a smaller ink without the padding.
        final ButtonStyle? style = build().iconButtonTheme.style;
        final Size? minimum = style?.minimumSize?.resolve(
          const <WidgetState>{},
        );

        expect(minimum, const Size.square(AppSizing.iconButtonInk));
        expect(style?.tapTargetSize, MaterialTapTargetSize.padded);
      });
    }
  });

  test('a row that leads with a tile puts its text on the divider indent', () {
    // The handoff fixes the icon tile steps, the 16 gutter, the 12 grouped gap
    // and the Divider indent (`0 / 56`); they agree only at the small tile
    // (UI audit P2, M100.91). A step that moves alone fails here.
    expect(
      AppSpacing.lg + AppSizing.iconTileSm + AppSpacing.md,
      AppSizing.listDividerIndent,
    );
  });
}
