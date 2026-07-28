import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/theme_context_extension.dart';

/// WCAG 2.1 relative luminance.
double _luminance(Color color) {
  double channel(double component) {
    return component <= 0.03928
        ? component / 12.92
        : math.pow((component + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG contrast ratio between two opaque colours, 1.0 to 21.0.
double _contrast(Color foreground, Color background) {
  final a = _luminance(foreground);
  final b = _luminance(background);

  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

/// The colour an OutlinedButton actually paints its label in, at rest.
Color _outlinedButtonLabel(ThemeData theme) =>
    theme.outlinedButtonTheme.style!.foregroundColor!.resolve(<WidgetState>{})!;

/// The colour a FilledButton actually paints in its resting state.
///
/// Read from the theme rather than from a token, so the test fails if the
/// button stops using what the palette intends for it.
Color _filledButtonFill(ThemeData theme) {
  final resolved = theme.filledButtonTheme.style!.backgroundColor!.resolve(
    <WidgetState>{},
  );

  return resolved!;
}

void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
  };

  group('contrast', () {
    test('_contrast matches known WCAG values', () {
      // Calibrates the helper before it is trusted to judge the palette: black
      // on white is exactly 21:1, and a colour against itself is 1:1.
      expect(
        _contrast(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.01),
      );
      expect(
        _contrast(const Color(0xFF4C5BD4), const Color(0xFF4C5BD4)),
        closeTo(1, 0.001),
      );
    });

    test('primary text pairs clear 4.5:1 in both themes', () {
      // Measured, not eyeballed. A palette judged by eye passes on the
      // reviewer's monitor and fails on a phone outdoors.
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;

        for (final pair in <(String, Color, Color)>[
          ('onSurface/surface', scheme.onSurface, scheme.surface),
          ('onPrimary/primary', scheme.onPrimary, scheme.primary),
          ('onError/error', scheme.onError, scheme.error),
          ('onSurfaceVariant/surface', scheme.onSurfaceVariant, scheme.surface),
        ]) {
          expect(
            _contrast(pair.$2, pair.$3),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key}: ${pair.$1} is below 4.5:1',
          );
        }
      }
    });

    test('semantic colours stay legible on their own surface', () {
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;
        final semantic = entry.value.extension<AppSemanticColors>()!;

        for (final pair in <(String, Color)>[
          ('success', semantic.success),
          ('warning', semantic.warning),
          ('danger', semantic.danger),
          ('info', semantic.info),
        ]) {
          expect(
            _contrast(pair.$2, scheme.surface),
            greaterThanOrEqualTo(3.0),
            reason: '${entry.key}: ${pair.$1} is below 3:1 on surface',
          );
        }
      }
    });
  });

  group('AppSemanticColors', () {
    test('copyWith replaces only what it is given', () {
      const base = AppSemanticColors.light();
      final changed = base.copyWith(danger: const Color(0xFF123456));

      expect(changed.danger, const Color(0xFF123456));
      expect(changed.success, base.success);
      expect(changed.warning, base.warning);
      expect(changed.info, base.info);
      expect(changed.surfaceMuted, base.surfaceMuted);
      expect(changed.borderSubtle, base.borderSubtle);
      expect(changed.focusRing, base.focusRing);
    });

    test('lerp interpolates every field, not just some', () {
      const light = AppSemanticColors.light();
      const dark = AppSemanticColors.dark();
      final mid = light.lerp(dark, 0.5);

      // A field left out of lerp snaps during a theme change, and the snap is
      // visible only on the one screen that uses it. Comparing every field to
      // Color.lerp catches the omission wherever it is.
      expect(mid.success, Color.lerp(light.success, dark.success, 0.5));
      expect(mid.warning, Color.lerp(light.warning, dark.warning, 0.5));
      expect(mid.danger, Color.lerp(light.danger, dark.danger, 0.5));
      expect(mid.info, Color.lerp(light.info, dark.info, 0.5));
      expect(
        mid.surfaceMuted,
        Color.lerp(light.surfaceMuted, dark.surfaceMuted, 0.5),
      );
      expect(
        mid.borderSubtle,
        Color.lerp(light.borderSubtle, dark.borderSubtle, 0.5),
      );
      expect(mid.focusRing, Color.lerp(light.focusRing, dark.focusRing, 0.5));
    });

    test('lerp at the endpoints returns the endpoints', () {
      const light = AppSemanticColors.light();
      const dark = AppSemanticColors.dark();

      expect(light.lerp(dark, 0).danger, light.danger);
      expect(light.lerp(dark, 1).danger, dark.danger);
    });

    test('lerp against a foreign extension keeps this one', () {
      const light = AppSemanticColors.light();

      expect(light.lerp(null, 0.5), same(light));
    });
  });

  group('primary as a fill', () {
    test('the dark primary is not a glare source', () {
      // Material 3's tone-80 default sits at luminance 0.565 — over half of
      // pure white. As the fill of a large button on a deep page that is
      // visual noise, and it drags the eye off the card content, which is the
      // one thing a review screen exists to show.
      final darkPrimary = themes['dark']!.colorScheme.primary;

      expect(
        _luminance(darkPrimary),
        lessThan(0.25),
        reason: 'dark primary is bright enough to read as a light source',
      );
    });

    test('the action fill is the top of the surface ladder in dark', () {
      // The reference builds its CTA out of the neutral ladder rather than out
      // of the brand hue: page -> card -> tile -> action, each step brighter.
      // Asserting the ORDER, not the values, so a future palette can move all
      // four without this test dictating the colours.
      final dark = themes['dark']!;
      final semantic = dark.extension<AppSemanticColors>()!;
      final ladder = <double>[
        _luminance(dark.scaffoldBackgroundColor),
        _luminance(dark.colorScheme.surface),
        _luminance(semantic.surfaceMuted),
        _luminance(_filledButtonFill(dark)),
      ];

      for (var i = 1; i < ladder.length; i++) {
        expect(
          ladder[i],
          greaterThan(ladder[i - 1]),
          reason: 'tier $i is not brighter than tier ${i - 1}',
        );
      }
    });

    test('the action fill is legible against the card it sits on', () {
      for (final entry in themes.entries) {
        final fill = _filledButtonFill(entry.value);

        expect(
          _contrast(fill, entry.value.colorScheme.surface),
          greaterThanOrEqualTo(1.5),
          reason: '${entry.key}: the button disappears into the card',
        );
        expect(
          _contrast(entry.value.colorScheme.onPrimary, fill),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}: label on the action fill',
        );
      }
    });

    test('the outlined label is readable on page AND on card', () {
      // The gap that let a 3.09:1 label ship: every contrast test here checked
      // a *fill* or a *text theme* colour, and none checked what an
      // OutlinedButton actually paints. Both surfaces are checked because a
      // secondary button sits on either one, and the card is the harsher of the
      // two in dark.
      for (final entry in themes.entries) {
        final label = _outlinedButtonLabel(entry.value);

        for (final background in <(String, Color)>[
          ('page', entry.value.scaffoldBackgroundColor),
          ('card', entry.value.colorScheme.surface),
        ]) {
          expect(
            _contrast(label, background.$2),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key}: outlined label on ${background.$1}',
          );
        }
      }
    });

    test('label on a primary fill is readable in both themes', () {
      // The failure this catches is specific: M3's light-on-light pairing gives
      // white text 1.71:1 on the tone-80 lavender, which passes no standard.
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;

        expect(
          _contrast(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}: onPrimary on primary',
        );
      }
    });
  });

  group('surface ladder', () {
    test('three distinct levels in both themes', () {
      // Two levels forces every inset element to borrow the card colour and
      // vanish into it; the third step is what lets a chip read as raised.
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;
        final semantic = entry.value.extension<AppSemanticColors>()!;

        final levels = <Color>{
          entry.value.scaffoldBackgroundColor,
          scheme.surface,
          semantic.surfaceMuted,
        };

        expect(levels, hasLength(3), reason: entry.key);
      }
    });

    test('page and card are separated enough to be seen apart', () {
      for (final entry in themes.entries) {
        final step = _contrast(
          entry.value.scaffoldBackgroundColor,
          entry.value.colorScheme.surface,
        );

        // Below roughly 1.05 the step stops being visible on a phone in
        // daylight, which is where a card silently becomes a flat region.
        expect(step, greaterThan(1.05), reason: entry.key);
      }
    });
  });

  group('input focus', () {
    test('focus changes the border colour, never its weight', () {
      // Material's default goes 1px -> 2px on focus. That makes the field jump
      // and nudges whatever is laid out beside it.
      for (final entry in themes.entries) {
        final input = entry.value.inputDecorationTheme;
        final enabled = input.enabledBorder! as OutlineInputBorder;
        final focused = input.focusedBorder! as OutlineInputBorder;

        expect(
          focused.borderSide.width,
          enabled.borderSide.width,
          reason: '${entry.key}: focus changed the stroke width',
        );
        expect(
          focused.borderSide.color,
          isNot(enabled.borderSide.color),
          reason: '${entry.key}: focus is not visible at all',
        );
        expect(
          focused.borderRadius,
          enabled.borderRadius,
          reason: '${entry.key}: focus changed the shape',
        );
      }
    });

    test('the focus ring is visible against the field it outlines', () {
      for (final entry in themes.entries) {
        final semantic = entry.value.extension<AppSemanticColors>()!;

        expect(
          _contrast(semantic.focusRing, semantic.surfaceMuted),
          greaterThanOrEqualTo(3.0),
          reason: entry.key,
        );
      }
    });
  });

  group('theme wiring', () {
    testWidgets('the same widget builds in light and dark without throwing', (
      tester,
    ) async {
      for (final entry in themes.entries) {
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: <Widget>[
                    Text('probe', style: context.texts.bodyMedium),
                    ColoredBox(
                      color: context.semanticColors.success,
                      child: const SizedBox.square(dimension: 8),
                    ),
                    FilledButton(onPressed: () {}, child: const Text('a')),
                    OutlinedButton(onPressed: () {}, child: const Text('b')),
                    const Card(child: SizedBox.square(dimension: 8)),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull, reason: entry.key);
      }
    });

    testWidgets('context.semanticColors explains a missing extension', (
      tester,
    ) async {
      // A silent default would render the wrong colour on a screen nobody
      // re-checks; this must fail loudly at the first build instead.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              context.semanticColors;

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('MemoxApp follows the system theme mode', (tester) async {
      // `themeMode` is not passed explicitly — it would be a redundant argument
      // and this project promotes that lint to error. Pin the behaviour here so
      // the omission stays deliberate rather than becoming an accident.
      await tester.pumpWidget(const MemoxApp());

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(app.themeMode, ThemeMode.system);
      expect(app.theme, isNotNull);
      expect(app.darkTheme, isNotNull);
    });
  });
}
