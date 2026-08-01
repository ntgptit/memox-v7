import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_breakpoints.dart';
import 'package:memox/core/theme/app_compact_scale.dart';
import 'package:memox/core/theme/app_durations.dart';
import 'package:memox/core/theme/app_elevation.dart';
import 'package:memox/core/theme/app_icon_size.dart';
import 'package:memox/core/theme/app_radius.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import 'css_tokens.dart';

/// **The scale half of CSS/Dart parity** — spacing, radius, icon, breakpoint,
/// elevation, motion and the type scale.
///
/// Split from `css_token_parity_test.dart` at the 400-line guard, on the seam
/// that file already had: colours are a long hand-maintained mapping with its
/// own completeness rules, and everything here is a handful of scalars read
/// straight off a token name. They share `css_tokens.dart` and nothing else.
///
/// The argument for parsing the CSS at all is in the header of
/// `css_token_parity_test.dart`.
void main() {
  final ThemeData light = buildLightTheme();
  final ThemeData dark = buildDarkTheme();

  group('the scales match the kit', () {
    test('spacing', () {
      expect(CssTokens.number('spacing.css', '--space-xs'), AppSpacing.xs);
      expect(CssTokens.number('spacing.css', '--space-sm'), AppSpacing.sm);
      expect(CssTokens.number('spacing.css', '--space-md'), AppSpacing.md);
      expect(CssTokens.number('spacing.css', '--space-lg'), AppSpacing.lg);
      expect(CssTokens.number('spacing.css', '--space-xl'), AppSpacing.xl);
      expect(CssTokens.number('spacing.css', '--space-xxl'), AppSpacing.xxl);
      expect(
        CssTokens.number('spacing.css', '--touch-target-min'),
        AppSpacing.minimumTouchTarget,
      );
    });

    test('icon sizes', () {
      expect(CssTokens.number('spacing.css', '--icon-sm'), AppIconSize.sm);
      expect(CssTokens.number('spacing.css', '--icon-md'), AppIconSize.md);
      expect(CssTokens.number('spacing.css', '--icon-lg'), AppIconSize.lg);
    });

    test('radius', () {
      expect(CssTokens.number('radius.css', '--radius-sm'), AppRadius.sm);
      expect(CssTokens.number('radius.css', '--radius-md'), AppRadius.md);
      expect(CssTokens.number('radius.css', '--radius-lg'), AppRadius.lg);
      expect(CssTokens.number('radius.css', '--radius-pill'), AppRadius.pill);
    });

    test('breakpoints', () {
      expect(
        CssTokens.number('layout.css', '--breakpoint-compact'),
        AppBreakpoints.compact,
      );
      expect(
        CssTokens.number('layout.css', '--breakpoint-medium'),
        AppBreakpoints.medium,
      );
    });

    test('elevation levels', () {
      expect(
        CssTokens.number('elevation.css', '--elevation-none'),
        AppElevation.none,
      );
      expect(
        CssTokens.number('elevation.css', '--elevation-card'),
        AppElevation.card,
      );
      expect(
        CssTokens.number('elevation.css', '--elevation-raised'),
        AppElevation.raised,
      );
      expect(
        CssTokens.number('elevation.css', '--elevation-overlay'),
        AppElevation.overlay,
      );
    });

    test('durations and easing', () {
      expect(
        CssTokens.number('motion.css', '--duration-fast'),
        AppDurations.fast.inMilliseconds,
      );
      expect(
        CssTokens.number('motion.css', '--duration-normal'),
        AppDurations.normal.inMilliseconds,
      );
      expect(
        CssTokens.number('motion.css', '--duration-slow'),
        AppDurations.slow.inMilliseconds,
      );
      // Written out because `Curves.decelerate` is `(0,0,0.2,1)` and the kit's
      // `--ease-decelerate` is `(0,0,0,1)` — close enough to look right and not
      // the same thing, which is the note `AppDurations` already carries.
      // Compared field by field: `Cubic` inherits identity equality, so `==`
      // between two structurally identical curves is false and the failure
      // message prints the same string twice.
      _expectSameCurve('--ease-standard', AppDurations.standard);
      _expectSameCurve('--ease-decelerate', AppDurations.decelerate);
    });

    test('border widths', () {
      // The input stroke is the one that moved once already: Material goes
      // 1px -> 2px on focus and this app holds 1.5 in every state.
      final border =
          light.inputDecorationTheme.enabledBorder! as OutlineInputBorder;
      expect(
        border.borderSide.width,
        CssTokens.number('elevation.css', '--border-input'),
      );

      final focusRing = (light.chipTheme.side! as WidgetStateBorderSide)
          .resolve(<WidgetState>{WidgetState.focused});
      expect(
        focusRing?.width,
        CssTokens.number('elevation.css', '--border-focus'),
      );

      expect(
        light.dividerTheme.thickness,
        CssTokens.number('elevation.css', '--border-hairline'),
      );
    });
  });

  group('the type scale matches the kit', () {
    /// One rung, read out of the built theme rather than out of `AppTypography`.
    /// A style is only correct where a component can reach it.
    void expectRung(
      String token,
      TextStyle? style, {
      String? leadingToken,
      String? trackingToken,
    }) {
      final size = CssTokens.number('typography.css', '--text-$token');
      expect(style?.fontSize, size, reason: '--text-$token');

      final leading = CssTokens.number(
        'typography.css',
        '--leading-${leadingToken ?? token}',
      );
      // The kit writes a leading in px where it has one and a bare ratio where
      // the design states a ratio; Flutter wants the ratio either way.
      expect(
        style?.height,
        closeTo(leading > 3 ? leading / size : leading, 0.0001),
        reason: '--leading-${leadingToken ?? token}',
      );

      if (trackingToken == null) return;
      expect(
        style?.letterSpacing,
        CssTokens.number('typography.css', '--tracking-$trackingToken'),
        reason: '--tracking-$trackingToken',
      );
    }

    test('display and headline rungs', () {
      final texts = light.textTheme;
      expectRung('display-lg', texts.displayLarge);
      expectRung('display-md', texts.displayMedium);
      expectRung('display-sm', texts.displaySmall);
      expectRung('headline-lg', texts.headlineLarge);
      expectRung(
        'card-prompt',
        texts.headlineMedium,
        trackingToken: 'card-prompt',
      );
      expectRung('headline-sm', texts.headlineSmall);
    });

    test('title, body and label rungs', () {
      final texts = light.textTheme;
      expectRung('title-lg', texts.titleLarge);
      expectRung('title-md', texts.titleMedium, trackingToken: 'title-md');
      expectRung('title-sm', texts.titleSmall, trackingToken: 'title-sm');
      expectRung('body-lg', texts.bodyLarge, trackingToken: 'body-lg');
      expectRung('body-md', texts.bodyMedium, trackingToken: 'body-md');
      expectRung('body-sm', texts.bodySmall, trackingToken: 'body-sm');
      expectRung('label-lg', texts.labelLarge, trackingToken: 'label-lg');
      expectRung('label-md', texts.labelMedium, trackingToken: 'label-md');
      expectRung('label-sm', texts.labelSmall, trackingToken: 'label-sm');
    });

    test('the two faces are the kit\'s two', () {
      // The kit writes a CSS font stack and Flutter names one bundled family,
      // so the comparison is against the head of the stack with its spaces
      // removed — `"Plus Jakarta Sans", …` against `PlusJakartaSans`.
      String head(String token) => CssTokens.require(
        'typography.css',
        token,
      ).split(',').first.replaceAll('"', '').replaceAll(' ', '');

      expect(head('--font-display'), AppTypography.displayFamily);
      expect(head('--font-body'), AppTypography.bodyFamily);
    });

    test('weights are the kit\'s four', () {
      final texts = light.textTheme;
      final weights = <String, FontWeight?>{
        'regular': texts.bodyMedium?.fontWeight,
        // `--weight-medium` had no assertion until M4.10ap, which made it the
        // one rung of the weight scale that could move without anything
        // noticing. It is what the two smallest labels are set in.
        'medium': texts.labelMedium?.fontWeight,
        'semibold': texts.labelLarge?.fontWeight,
        'bold': texts.displayLarge?.fontWeight,
      };

      for (final entry in weights.entries) {
        expect(
          entry.value?.value,
          CssTokens.number('typography.css', '--weight-${entry.key}'),
          reason: '--weight-${entry.key}',
        );
      }
    });

    test('the compact rungs and the section-label tracking', () {
      expect(
        CssTokens.number('typography.css', '--text-card-prompt-compact'),
        AppTypography.compactCardPromptSize,
      );
      expect(
        CssTokens.number('typography.css', '--tracking-section-label'),
        AppTypography.sectionLabelTracking,
      );
      // Read off the compact theme rather than a constant: `app_compact_scale.dart`
      // sets the app-bar title inline, so a constant to compare against does not
      // exist and asserting one would only prove the test agrees with itself.
      expect(
        applyCompactScale(light).textTheme.titleLarge?.fontSize,
        CssTokens.number('typography.css', '--text-title-lg-compact'),
      );
    });
  });

  group('what the kit states as a value, the app computes', () {
    test('a shadow at each level is the kit\'s shadow', () {
      // `shadowsFor` derives offset, blur and alpha from the level — the alpha
      // was solved for, not picked — where the kit has to write three literals.
      // So this is the one place the *formula* is checked against the values,
      // and it is why the elevation tokens can be in parity at all.
      for (final (String token, double level) in <(String, double)>[
        ('--shadow-card', AppElevation.card),
        ('--shadow-raised', AppElevation.raised),
        ('--shadow-overlay', AppElevation.overlay),
      ]) {
        final declared = _shadow('elevation.css', token);
        final shadows = shadowsFor(level, light.colorScheme);

        expect(shadows, hasLength(1), reason: '$token: expected one shadow');
        expect(shadows.single.offset.dy, declared.dy, reason: '$token offset');
        expect(shadows.single.blurRadius, declared.blur, reason: '$token blur');
        expect(
          shadows.single.color.a,
          closeTo(declared.alpha, 0.005),
          reason: '$token alpha',
        );
      }
    });

    test('dark drops every shadow, as the kit does', () {
      // `[data-theme="dark"]` re-points all three to `none`. The Dart side says
      // the same thing by returning an empty list, and the two agreeing is what
      // makes "no shadow in dark" a shared decision rather than a coincidence.
      for (final token in <String>[
        '--shadow-card',
        '--shadow-raised',
        '--shadow-overlay',
      ]) {
        expect(
          CssTokens.require(
            'elevation.css',
            token,
            scope: '[data-theme="dark"]',
          ),
          'none',
          reason: '$token still paints in dark',
        );
      }

      for (final level in AppElevation.scale) {
        expect(
          shadowsFor(level, dark.colorScheme),
          isEmpty,
          reason: 'level $level paints a shadow in dark',
        );
      }
    });

    test('the navigation bar caps at the kit\'s width per destination', () {
      expect(
        widthPerNavigationDestination,
        CssTokens.number('layout.css', '--nav-width-per-destination'),
      );
    });
  });
}

/// `0 1px 3px rgb(r g b / a)` — the parts Flutter needs.
({double dy, double blur, double alpha}) _shadow(String file, String token) {
  final raw = CssTokens.require(file, token);
  final match = RegExp(
    r'^0\s+(\d+)px\s+(\d+)px\s+rgb\([^/]+/\s*([\d.]+)\s*\)$',
  ).firstMatch(raw);
  if (match == null) {
    throw StateError('$token is "$raw", which is not a single offset shadow');
  }

  return (
    dy: double.parse(match.group(1)!),
    blur: double.parse(match.group(2)!),
    alpha: double.parse(match.group(3)!),
  );
}

void _expectSameCurve(String token, Curve dart) {
  // `AppDurations` types these as `Curve`, so the cast is also the assertion
  // that the app has not quietly swapped one of them for a `Curves.` preset —
  // which is how `--ease-decelerate` and `Curves.decelerate` got confused once.
  expect(dart, isA<Cubic>(), reason: '$token is no longer a cubic-bezier');
  final curve = dart as Cubic;

  final kit = _cubic('motion.css', token);
  expect(kit.a, curve.a, reason: '$token a');
  expect(kit.b, curve.b, reason: '$token b');
  expect(kit.c, curve.c, reason: '$token c');
  expect(kit.d, curve.d, reason: '$token d');
}

/// `cubic-bezier(a,b,c,d)` as the [Cubic] Flutter wants.
Cubic _cubic(String file, String token) {
  final raw = CssTokens.require(file, token);
  final match = RegExp(
    r'cubic-bezier\(\s*([\d.-]+)\s*,\s*([\d.-]+)\s*,\s*([\d.-]+)\s*,\s*([\d.-]+)\s*\)',
  ).firstMatch(raw);
  if (match == null) {
    throw StateError('$token is "$raw", which is not a cubic-bezier');
  }

  return Cubic(
    double.parse(match.group(1)!),
    double.parse(match.group(2)!),
    double.parse(match.group(3)!),
    double.parse(match.group(4)!),
  );
}
