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
    test('every control dimension sits on the 4dp grid', () {
      // Structural geometry follows the 4dp rhythm; stroke, type size and
      // opacity have scales of their own and are not covered by this rule.
      for (final (String name, double value) in <(String, double)>[
        ('touchTarget', AppSizing.touchTarget),
        ('controlCompact', AppSizing.controlCompact),
        ('floatingAction', AppSizing.floatingAction),
        ('buttonMinWidth', AppSizing.buttonMinWidth),
      ]) {
        expect(
          value % 4,
          0,
          reason: '$name is $value, which is off the 4dp grid',
        );
      }
    });

    test('the compact body is smaller than the target it keeps', () {
      // The whole point of the compact tier: the body comes down, the finger's
      // floor does not. If these ever met, `MaterialTapTargetSize.padded` would
      // be doing nothing and the tier would be a second name for `standard`.
      expect(AppSizing.controlCompact, lessThan(AppSizing.touchTarget));
    });

    test('the FAB clearance is derived from the FAB, not repeated', () {
      // `AppSpacing.fabScrollClearance` is the button plus a gap on each side.
      // Written as arithmetic over the token rather than as a fourth literal,
      // so a FAB that ever changed size could not leave the clearance behind.
      expect(
        AppSpacing.fabScrollClearance,
        AppSizing.floatingAction + AppSpacing.lg + AppSpacing.lg,
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
        final Size? minimum = build().iconButtonTheme.style?.minimumSize
            ?.resolve(const <WidgetState>{});

        expect(minimum, isNotNull);
        expect(minimum!.height, AppSizing.touchTarget);
        expect(minimum.width, AppSizing.touchTarget);
      });
    }
  });
}
