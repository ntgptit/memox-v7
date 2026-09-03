import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/components/actions/app_button_themes.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

import '../../support/color_math.dart';
import '../../support/ink_probe.dart';

/// **What a filled button actually paints under a pointer — the composite,
/// not the two halves.**
///
/// `mx_action_button_state_matrix_test.dart` resolves `backgroundColor` and
/// `overlayColor` separately, and that is how a double-feedback defect lived
/// for six milestones (#432 §5): `ButtonStyleButton` puts the first on a
/// `Material` and the second on the `InkWell` inside it, both paint, and no
/// test ever asked what the pixel underneath the finger ended up as. On the
/// error fill it ended up indigo — `primary` at 12% over `error`, hue rotated
/// 345.7° → 338.5°.
///
/// Every assertion here is on `alphaBlend(overlay(state), background(state))`,
/// which is the model `focus_ring_contrast_test.dart` already uses for the
/// focus wash, and the last group drives a real press so the rendered ink is
/// checked once rather than inferred.
///
/// **The contract, from `_FilledButtonDefaultsM3` at 3.44.8:** the background
/// is its role in every enabled state; hover, focus and press are a state
/// layer in the fill's own `on` colour at 0.08 / 0.10 / 0.10. In this palette
/// every `on` colour is white or near-black against its fill, so the layer
/// moves lightness and leaves hue where it was.
void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
    'high-contrast light': buildHighContrastLightTheme(),
    'high-contrast dark': buildHighContrastDarkTheme(),
  };

  const variants = <String, (MxActionButtonVariant, MxFilledPair)>{
    'primary': (MxActionButtonVariant.primary, MxFilledPair.brand),
    'destructive': (
      MxActionButtonVariant.destructive,
      MxFilledPair.destructive,
    ),
  };

  const rest = <WidgetState>{};
  const hovered = <WidgetState>{WidgetState.hovered};
  const pressed = <WidgetState>{WidgetState.pressed};
  const focused = <WidgetState>{WidgetState.focused};

  /// The floors below are **regression floors, not design targets.** The
  /// alphas are M3's (`_FilledButtonDefaultsM3.overlayColor`, 3.44.8) and are
  /// not up for tuning here; what these numbers catch is a layer that lost
  /// its colour or its alpha. Measured minima on this palette, recorded so the
  /// next person sees the margin: press/focus 2.37 (light `error`, white at
  /// 10% on a saturated dark red), hover 1.82 (same fill at 8%); every other
  /// pair × theme lands 3.5–5.5 on press. The assertions that carry the
  /// defect #432 found are the other three — an unmoved fill, a layer in the
  /// pair's own ink, and no hue rotation — not this one.
  const double visibleStep = 2.0;
  const double hoverStep = 1.5;

  /// Above this the layer has stopped being a state and become a colour
  /// change — the destructive press measured ΔE 11.7 before M100.36.
  const double overshoot = 12;

  Future<ButtonStyle> effectiveStyle(
    WidgetTester tester,
    ThemeData theme,
    MxActionButtonVariant variant,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: MxActionButton(
              label: 'Remembered',
              variant: variant,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final context = tester.element(find.byType(FilledButton));
    // The widget's own style first, the theme slot for the rest — the same
    // order `ButtonStyleButton.resolve` takes.
    final ButtonStyle themed = FilledButtonTheme.of(context).style!;

    return button.style == null ? themed : button.style!.merge(themed);
  }

  Color composite(ButtonStyle style, Set<WidgetState> states) {
    final Color background = style.backgroundColor!.resolve(states)!;
    final Color? overlay = style.overlayColor?.resolve(states);

    return overlay == null ? background : Color.alphaBlend(overlay, background);
  }

  for (final themeEntry in themes.entries) {
    final themeName = themeEntry.key;
    final theme = themeEntry.value;

    group(themeName, () {
      for (final variantEntry in variants.entries) {
        final variantName = variantEntry.key;
        final (variant, pair) = variantEntry.value;

        testWidgets('$variantName · the background is its role in every '
            'enabled state', (tester) async {
          final style = await effectiveStyle(tester, theme, variant);
          final Color restFill = style.backgroundColor!.resolve(rest)!;

          expect(restFill, pair.fillOf(theme.colorScheme), reason: themeName);
          for (final states in <Set<WidgetState>>[hovered, pressed, focused]) {
            expect(
              style.backgroundColor!.resolve(states),
              restFill,
              reason:
                  '$themeName $variantName: the fill itself moved under '
                  '$states — that is the retired blend, not a state layer',
            );
          }
        });

        testWidgets('$variantName · the state layer is the pair-s own ink, '
            'never the brand', (tester) async {
          final style = await effectiveStyle(tester, theme, variant);
          final Color ink = pair.labelOf(theme.colorScheme);

          for (final states in <Set<WidgetState>>[hovered, pressed, focused]) {
            final Color? overlay = style.overlayColor?.resolve(states);
            expect(overlay, isNotNull, reason: '$variantName has no layer');
            expect(
              overlay!.withValues(alpha: 1),
              ink,
              reason:
                  '$themeName $variantName: the state layer under $states is '
                  'not the fill-s own `on` colour',
            );
          }
          expect(
            style.overlayColor?.resolve(rest),
            isNull,
            reason: '$themeName $variantName: a resting fill paints a layer',
          );
        });

        testWidgets('$variantName · the composite moves lightness, holds hue, '
            'and stays inside the band', (tester) async {
          final style = await effectiveStyle(tester, theme, variant);
          final Color restPixel = composite(style, rest);
          final double? restHue = hue(restPixel);

          for (final (String name, Set<WidgetState> states, double floor)
              in <(String, Set<WidgetState>, double)>[
                ('hover', hovered, hoverStep),
                ('press', pressed, visibleStep),
                ('focus', focused, visibleStep),
              ]) {
            final Color pixel = composite(style, states);
            final double step =
                (lightnessStar(pixel) - lightnessStar(restPixel)).abs();

            expect(
              step,
              greaterThanOrEqualTo(floor),
              reason:
                  '$themeName $variantName $name: ΔL* $step — the state is '
                  'invisible on the release target',
            );
            expect(
              step,
              lessThanOrEqualTo(overshoot),
              reason:
                  '$themeName $variantName $name: ΔL* $step — the layer has '
                  'become a colour change',
            );

            // Hue is compared only where both sides have one; a white or
            // near-black `on` colour composited at 10% cannot rotate a
            // chromatic fill, and this is the assertion that says so.
            final double? pixelHue = hue(pixel);
            if (restHue == null || pixelHue == null) continue;
            final double rotation = ((pixelHue - restHue).abs() % 360);
            expect(
              rotation < 4 || rotation > 356,
              isTrue,
              reason:
                  '$themeName $variantName $name: hue rotated '
                  '${rotation.toStringAsFixed(1)}° — a foreign colour is '
                  'being washed over this fill',
            );
          }
        });

        testWidgets('$variantName · the label still clears AA on the pressed '
            'composite', (tester) async {
          final style = await effectiveStyle(tester, theme, variant);
          final Color label = style.foregroundColor!.resolve(pressed)!;

          expect(
            contrast(label, composite(style, pressed)),
            greaterThanOrEqualTo(4.5),
            reason: '$themeName $variantName: label under AA while pressed',
          );
        });
      }
    });
  }

  group('a real press paints the layer on the button-s own Material', () {
    // Everything above is arithmetic on resolved properties. This is the one
    // place the pixel is read off the tree: the pressed `InkHighlight` paints
    // `overlayColor.resolve({pressed})` at full alpha once its fade is done,
    // so finding that colour in an ink layer proves the mechanism reached the
    // canvas — and finding the brand colour there on the error fill would be
    // the defect coming back.
    for (final variantEntry in variants.entries) {
      final variantName = variantEntry.key;
      final (variant, pair) = variantEntry.value;

      testWidgets(variantName, (tester) async {
        final theme = buildLightTheme();
        final style = await effectiveStyle(tester, theme, variant);
        final Color expected = style.overlayColor!.resolve(pressed)!;
        final Color foreign = theme.colorScheme.primary.withValues(alpha: 0.12);

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(FilledButton)),
        );
        // Two pumps: a `Ticker` counts from its first tick, so one long pump
        // lands on the highlight's first frame at alpha 0.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expectInkColor(
          tester,
          expected,
          reason: '$variantName: the pair-s state layer never reached the ink',
        );
        if (pair != MxFilledPair.brand) {
          expectNoInkColor(
            tester,
            foreign,
            reason: '$variantName: the brand wash is back on a non-brand fill',
          );
        }

        await gesture.up();
        await tester.pumpAndSettle();
      });
    }
  });
}
