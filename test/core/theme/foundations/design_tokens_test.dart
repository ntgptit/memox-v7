import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/core/theme/foundations/app_colors.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/components/app_overlay_themes.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/foundations/app_surface_colors.dart';
import 'package:memox/core/theme/foundations/app_border_colors.dart';

void main() {
  group('AppSpacing', () {
    test('is exactly the 4/8/12/16/24/32 scale', () {
      expect(AppSpacing.scale, <double>[4, 8, 12, 16, 24, 32]);
    });

    test('the scale is strictly increasing and has no duplicates', () {
      // A duplicated step means two names for one value, and the two drift
      // apart the first time someone "fixes" only one of them.
      for (var i = 1; i < AppSpacing.scale.length; i++) {
        expect(AppSpacing.scale[i], greaterThan(AppSpacing.scale[i - 1]));
      }
    });

    test('every declared constant is on the scale', () {
      // Guards the failure this token file exists to prevent: a seventh
      // constant added quietly, off-scale, for one screen.
      const declared = <double>[
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ];

      expect(declared.toSet(), AppSpacing.scale.toSet());
    });
  });

  group('required tokens exist', () {
    test('radius, icon size, duration and breakpoint tokens are present', () {
      expect(AppRadius.sm, lessThan(AppRadius.md));
      expect(AppRadius.md, lessThan(AppRadius.lg));
      expect(AppRadius.pill, greaterThan(AppRadius.lg));

      expect(AppIconSize.sm, lessThan(AppIconSize.md));
      expect(AppIconSize.md, lessThan(AppIconSize.lg));

      expect(AppDurations.fast, lessThan(AppDurations.normal));
      expect(AppDurations.normal, lessThan(AppDurations.slow));
      // Motion during a review must not become something the user waits on.
      expect(AppDurations.slow.inMilliseconds, lessThanOrEqualTo(400));

      expect(AppBreakpoints.compact, lessThan(AppBreakpoints.medium));
    });

    test('semantic colours are defined for both brightnesses', () {
      // A meaning that exists in light but not dark is a hole nobody finds
      // until someone switches theme on the screen that uses it.
      expect(AppColors.successLight, isNot(AppColors.successDark));
      expect(AppColors.warningLight, isNot(AppColors.warningDark));
      expect(AppColors.dangerLight, isNot(AppColors.dangerDark));
      expect(AppColors.infoLight, isNot(AppColors.infoDark));
      expect(
        AppSurfaceColors.surfaceMutedLight,
        isNot(AppSurfaceColors.surfaceMutedDark),
      );
      expect(
        AppBorderColors.borderSubtleLight,
        isNot(AppBorderColors.borderSubtleDark),
      );
    });
  });

  group('AppStroke', () {
    test('carries the three canonical widths', () {
      // Named against the values rather than against each other: a stroke scale
      // that only has to be *increasing* passes with 1 / 1.6 / 3, which is three
      // numbers nobody chose.
      expect(AppStroke.hairline, 1);
      expect(AppStroke.input, 1.5);
      expect(AppStroke.focus, 2);
    });

    test('matches design_system/tokens/elevation.css', () {
      // The kit is where these values are decided, and a Dart constant that
      // silently drifts from it is exactly the divergence this project keeps
      // finding by eye. Parsed rather than transcribed, so the two cannot part
      // company without this failing.
      final css = File('design_system/tokens/elevation.css').readAsStringSync();

      double declared(String token) {
        final match = RegExp('--border-$token:\\s*([0-9.]+)px').firstMatch(css);
        expect(match, isNotNull, reason: '--border-$token is not in the kit');

        return double.parse(match!.group(1)!);
      }

      expect(AppStroke.hairline, declared('hairline'));
      expect(AppStroke.input, declared('input'));
      expect(AppStroke.focus, declared('focus'));
    });
  });

  test('a tooltip delay is not a motion duration', () {
    // Why `kTooltipWaitDuration` lives beside the tooltip theme instead of
    // becoming a fourth rung on this scale: `AppDurations.slow` is documented as
    // the ceiling on motion, so parking a 500ms interaction delay there would
    // say the app may animate for half a second.
    expect(kTooltipWaitDuration, greaterThan(AppDurations.slow));
  });

  test('colour tokens are named for meaning, not appearance', () {
    // `red` becomes a lie the moment the palette changes, and nobody renames a
    // constant used in forty files.
    final source = File(
      'lib/core/theme/foundations/app_colors.dart',
    ).readAsStringSync();
    final declarations = RegExp(
      r'static const Color (\w+)',
    ).allMatches(source).map((m) => m.group(1)!).toList();

    expect(declarations, isNotEmpty);
    for (final name in declarations) {
      for (final physical in <String>[
        'red',
        'green',
        'blue',
        'yellow',
        'orange',
        'purple',
        'grey',
        'gray',
      ]) {
        expect(
          name.toLowerCase(),
          isNot(contains(physical)),
          reason: '$name is named after its appearance',
        );
      }
    }
  });

  test('token classes cannot be instantiated', () {
    // `abstract final class` is what makes AppSpacing() a compile error rather
    // than a meaningless object; assert the declaration rather than the type.
    for (final path in <String>[
      'foundations/app_spacing',
      'foundations/app_sizing',
      'foundations/app_radius',
      'foundations/app_icon_size',
      'foundations/app_durations',
      'foundations/app_breakpoints',
      'foundations/app_colors',
      'foundations/app_stroke',
      'foundations/app_motion_policy',
      'typography/app_typography',
      'states/app_interaction_states',
    ]) {
      final source = File('lib/core/theme/$path.dart').readAsStringSync();

      expect(
        source,
        contains('abstract final class'),
        reason: '$path.dart must not be instantiable',
      );
    }
  });
}
