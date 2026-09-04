import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/schemes/app_compact_scale.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_elevation.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/typography/app_text_styles.dart';
import 'package:memox/core/theme/typography/app_typography.dart';
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
        AppSizing.touchTarget,
      );
    });

    test('icon sizes', () {
      expect(CssTokens.number('spacing.css', '--icon-sm'), AppIconSize.sm);
      expect(CssTokens.number('spacing.css', '--icon-md'), AppIconSize.md);
      expect(
        CssTokens.number('spacing.css', '--icon-md-compact'),
        AppIconSize.mdCompact,
      );
      expect(CssTokens.number('spacing.css', '--icon-lg'), AppIconSize.lg);
    });

    test('radius', () {
      expect(CssTokens.number('radius.css', '--radius-sm'), AppRadius.sm);
      expect(CssTokens.number('radius.css', '--radius-md'), AppRadius.md);
      expect(CssTokens.number('radius.css', '--radius-lg'), AppRadius.lg);
      expect(CssTokens.number('radius.css', '--radius-xl'), AppRadius.xl);
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
        CssTokens.number('elevation.css', '--border-control'),
      );

      // Read from the ring's one definition rather than off a component.
      // This used to resolve `chipTheme.side` under focus, which worked only
      // while the chip was carrying the ring in its identity slot — the
      // arrangement M100.23 ended. A width read from a component measures
      // whichever slot that component happens to use today.
      expect(
        AppInteractionStates.focusIndicator(light.colorScheme).width,
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
      // `--text-card-prompt` sits beside the scale in the kit, and it now
      // does in Flutter too: `AppTextStyles.cardPrompt`, not a rung.
      expectRung(
        'card-prompt',
        light.extension<AppTextStyles>()?.cardPrompt,
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
      // **Two layers per level since M100.30**, and the pair is checked in
      // order: the wide float first, the tight contact layer second. The kit
      // writes both in one CSS value because that is what `box-shadow` takes,
      // and a check that read only the first would have passed while the app
      // dropped the layer that says where the card touches.
      //
      // The colour is asserted too, which it was not before. It could be left
      // out while `--color-shadow` and the scrim were one token; they parted at
      // M100.30, so "the kit and the app agree on a shadow" now includes
      // agreeing on which of the two it is.
      for (final (String token, double level) in <(String, double)>[
        ('--shadow-card', AppElevation.card),
        ('--shadow-raised', AppElevation.raised),
        ('--shadow-overlay', AppElevation.overlay),
      ]) {
        final declared = _shadowLayers('elevation.css', token);
        final shadows = shadowsFor(level, light.colorScheme);

        expect(
          shadows,
          hasLength(declared.length),
          reason: '$token: the kit declares ${declared.length} layer(s)',
        );
        for (var i = 0; i < declared.length; i++) {
          expect(
            shadows[i].offset.dy,
            declared[i].dy,
            reason: '$token layer $i offset',
          );
          expect(
            shadows[i].blurRadius,
            declared[i].blur,
            reason: '$token layer $i blur',
          );
          expect(
            shadows[i].spreadRadius,
            declared[i].spread,
            reason: '$token layer $i spread',
          );
          expect(
            shadows[i].color.a,
            closeTo(declared[i].alpha, 0.005),
            reason: '$token layer $i alpha',
          );
          expect(
            <int>[
              (shadows[i].color.r * 255).round(),
              (shadows[i].color.g * 255).round(),
              (shadows[i].color.b * 255).round(),
            ],
            declared[i].rgb,
            reason: '$token layer $i colour',
          );
        }
      }
    });

    test('dark paints what Dart paints at every level — kit vs built theme', () {
      // **A20.1 P1-06.** Until the Design System V1 closure this test asserted
      // that the kit held three string literals copied from the kit — Tokyo's
      // `0 0 2px #6A7199` halo, stepping 1/2/3 — and separately that Dart drew
      // a hairline `outlineVariant` rim. Both passed while the two systems
      // disagreed on colour, blur and spread: a gate comparing a file to a
      // copy of itself. The kit is a mirror of Dart (owner decision 1), so the
      // comparison runs the same way light's does: parse the kit's layers and
      // hold them against `shadowsFor(level, dark.colorScheme)`.
      //
      // OLD ASSERTION: kit dark tokens == three literals (from the kit) and
      //   Dart's rim == outlineVariant, checked independently.
      // WHY WRONG: it could not fail when kit and Dart diverged — and they had.
      // NEW CONTRACT: every kit dark layer equals the built theme's layer in
      //   colour, alpha, blur, spread and offset, in order.
      // AUTHORITY: A20.1 P1-06 / §20 OD1; `_darkDepth` is the source of truth.
      expect(shadowsFor(AppElevation.none, dark.colorScheme), isEmpty);
      final Color rimColor = dark.colorScheme.outlineVariant;

      for (final (String token, double level) in <(String, double)>[
        ('--shadow-card', AppElevation.card),
        ('--shadow-raised', AppElevation.raised),
        ('--shadow-overlay', AppElevation.overlay),
      ]) {
        final declared = _shadowLayers(
          'elevation.css',
          token,
          scope: '[data-theme="dark"]',
        );
        final shadows = shadowsFor(level, dark.colorScheme);

        expect(
          shadows,
          hasLength(declared.length),
          reason: '$token: the kit declares ${declared.length} layer(s)',
        );
        for (var i = 0; i < declared.length; i++) {
          expect(shadows[i].offset.dy, declared[i].dy, reason: '$token $i dy');
          expect(
            shadows[i].blurRadius,
            declared[i].blur,
            reason: '$token $i blur',
          );
          expect(
            shadows[i].spreadRadius,
            declared[i].spread,
            reason: '$token $i spread',
          );
          expect(
            shadows[i].color.a,
            closeTo(declared[i].alpha, 0.005),
            reason: '$token $i alpha',
          );
          expect(
            _rgbOf(shadows[i].color),
            declared[i].rgb,
            reason: '$token $i',
          );
        }

        // **The rim is the first entry at every level and never changes**
        // (M100.35): outlineVariant, one hairline of spread, no blur. Depth
        // above `card` is the drop that follows it, never a wider ring.
        final rim = shadows.first;
        expect(rim.color, rimColor, reason: '$token rim colour');
        expect(rim.blurRadius, 0, reason: '$token rim blur');
        expect(rim.spreadRadius, AppStroke.hairline, reason: '$token rim');
        expect(rim.offset, Offset.zero, reason: '$token rim offset');
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

/// Every layer of a `box-shadow`, in order — `0 dy blur [spread] colour`
/// in px, where the colour is `rgb(r g b / a)` or a `#RRGGBB` hex.
///
/// Comma-separated, because a Tokyo shadow is a float plus a contact layer and
/// CSS writes both inside one value. Splitting on `,` is safe here and only
/// here: the kit's shadows use the space-separated `rgb()` form, which carries
/// no comma of its own. A parser that returned only the first layer would
/// silently stop checking the second — the failure mode this file exists for.
///
/// The spread and the hex form arrived with A20.1 P1-06: dark's rim is
/// `0 0 0 1px #272C48`, and a parser that could not read it is how the dark
/// gate ended up comparing literals instead of layers.
List<({double dy, double blur, double spread, double alpha, List<int> rgb})>
_shadowLayers(String file, String token, {String? scope}) {
  final raw = scope == null
      ? CssTokens.require(file, token)
      : CssTokens.require(file, token, scope: scope);

  return raw.split(',').map((String layer) {
    final match = RegExp(
      r'^0\s+(\d+)(?:px)?\s+(\d+)(?:px)?(?:\s+(\d+)px)?\s+'
      r'(?:rgb\(\s*(\d+)\s+(\d+)\s+(\d+)\s*/\s*([\d.]+)\s*\)|#([0-9A-Fa-f]{6}))$',
    ).firstMatch(layer.trim());
    if (match == null) {
      throw StateError('$token has a layer "$layer" this parser cannot read');
    }

    final String? hex = match.group(8);
    final List<int> rgb = hex == null
        ? <int>[
            int.parse(match.group(4)!),
            int.parse(match.group(5)!),
            int.parse(match.group(6)!),
          ]
        : <int>[
            int.parse(hex.substring(0, 2), radix: 16),
            int.parse(hex.substring(2, 4), radix: 16),
            int.parse(hex.substring(4, 6), radix: 16),
          ];

    return (
      dy: double.parse(match.group(1)!),
      blur: double.parse(match.group(2)!),
      spread: double.parse(match.group(3) ?? '0'),
      alpha: hex == null ? double.parse(match.group(7)!) : 1.0,
      rgb: rgb,
    );
  }).toList();
}

List<int> _rgbOf(Color color) => <int>[
  (color.r * 255).round(),
  (color.g * 255).round(),
  (color.b * 255).round(),
];

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
