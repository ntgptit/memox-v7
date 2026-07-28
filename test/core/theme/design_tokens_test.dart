import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_breakpoints.dart';
import 'package:memox/core/theme/app_colors.dart';
import 'package:memox/core/theme/app_durations.dart';
import 'package:memox/core/theme/app_icon_size.dart';
import 'package:memox/core/theme/app_radius.dart';
import 'package:memox/core/theme/app_spacing.dart';

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
      expect(AppColors.surfaceMutedLight, isNot(AppColors.surfaceMutedDark));
      expect(AppColors.borderSubtleLight, isNot(AppColors.borderSubtleDark));
    });
  });

  test('colour tokens are named for meaning, not appearance', () {
    // `red` becomes a lie the moment the palette changes, and nobody renames a
    // constant used in forty files.
    final source = File('lib/core/theme/app_colors.dart').readAsStringSync();
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
      'app_spacing',
      'app_radius',
      'app_icon_size',
      'app_durations',
      'app_breakpoints',
      'app_colors',
      'app_typography',
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
