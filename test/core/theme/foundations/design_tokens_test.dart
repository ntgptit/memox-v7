import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/core/theme/foundations/app_colors.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/components/feedback/app_tooltip_theme.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/foundations/app_surface_colors.dart';
import 'package:memox/core/theme/foundations/app_border_colors.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/shared/widgets/mx_icon.dart';

void main() {
  group('AppSpacing', () {
    test("is exactly the handoff's 4/8/12/16/20/24/32/48 scale", () {
      expect(AppSpacing.scale, <double>[4, 8, 12, 16, 20, 24, 32, 48]);
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
        AppSpacing.card,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ];

      expect(declared.toSet(), AppSpacing.scale.toSet());
    });
  });

  group('required tokens exist', () {
    test("radius ladder is the handoff's", () {
      expect(
        <double>[
          AppRadius.xs,
          AppRadius.sm,
          AppRadius.md,
          AppRadius.lg,
          AppRadius.card,
          AppRadius.xl,
          AppRadius.xxl,
          AppRadius.full,
        ],
        <double>[4, 8, 12, 16, 20, 24, 28, 999],
      );
    });

    test("icon ladder is the handoff's", () {
      expect(
        <double>[
          AppIconSize.xs,
          AppIconSize.sm,
          AppIconSize.md,
          AppIconSize.lg,
          AppIconSize.xl,
        ],
        <double>[16, 20, 24, 32, 40],
      );
      expect(MxIconSize.values.map((s) => s.dp), <double>[16, 20, 24, 32, 40]);
    });

    test('pressed state layer is the handoff op-press', () {
      expect(AppStateOpacity.stateLayerPressed, 0.12);
    });

    test('duration and breakpoint tokens are present', () {
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
      expect(AppStroke.control, 1.5);
      expect(AppStroke.focus, 2);
    });
  });

  test('a tooltip delay is not a motion duration', () {
    // Why `kTooltipWaitDuration` lives beside the tooltip theme instead of
    // becoming a fourth rung on this scale: `AppDurations.slow` is documented as
    // the ceiling on motion, so parking a 500ms interaction delay there would
    // say the app may animate for half a second.
    expect(kTooltipWaitDuration, greaterThan(AppDurations.slow));
  });

  /// The appearance words a colour token may not be named after.
  const physicalWords = <String>{
    'red',
    'green',
    'blue',
    'yellow',
    'orange',
    'purple',
    'grey',
    'gray',
  };

  /// Whether [name] carries an appearance word **as a word**.
  ///
  /// By camelCase word, not by substring (M100.91): `statusMasteredLight`
  /// contains `red` inside `Mastered`, and a substring check called a meaning
  /// name an appearance name — the same would happen to any `Registered`,
  /// `Deferred` or `Covered`.
  bool isAppearanceName(String name) => RegExp(r'[A-Z]?[a-z]+|[A-Z]+|\d+')
      .allMatches(name)
      .map((Match m) => m.group(0)!.toLowerCase())
      .any(physicalWords.contains);

  test('the appearance check reads words, not substrings', () {
    // Probes, so the rule cannot pass by matching nothing.
    expect(isAppearanceName('successGreenLight'), isTrue);
    expect(isAppearanceName('redLight'), isTrue);
    expect(isAppearanceName('onGreyContainer'), isTrue);
    expect(isAppearanceName('statusMasteredLight'), isFalse);
    expect(isAppearanceName('borderedSurfaceDark'), isFalse);
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
      expect(
        isAppearanceName(name),
        isFalse,
        reason: '$name is named after its appearance',
      );
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
