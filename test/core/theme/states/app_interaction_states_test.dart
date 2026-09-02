import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/components/app_button_themes.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/core/theme/components/app_overlay_themes.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/app_theme.dart';

/// The interaction-state contract, at the theme layer.
///
/// **What these tests are for is the state that is not written down.** Material
/// supplies a default for every property a theme leaves null, so a missing
/// decision renders as a made one — `ThemeData.hoverColor` is a hardcoded black
/// wash with no seed in it and no difference between modes, and no source scan
/// can see it because it exists only in the framework. Asserting that each
/// property *resolves* is therefore the point, not a formality.
void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
  };

  const hovered = <WidgetState>{WidgetState.hovered};
  const pressed = <WidgetState>{WidgetState.pressed};
  const focused = <WidgetState>{WidgetState.focused};
  const disabled = <WidgetState>{WidgetState.disabled};
  const resting = <WidgetState>{};

  group('the filled button', () {
    test('hover, press and disabled each land on their own fill', () {
      for (final entry in themes.entries) {
        final style = entry.value.filledButtonTheme.style!;
        final fill = style.backgroundColor!;
        final rest = fill.resolve(resting);

        expect(
          fill.resolve(hovered),
          isNot(rest),
          reason:
              '${entry.key}: hover is invisible — a 6% accent overlay on an '
              'accent fill is the accent again, which is why this is a blend',
        );
        expect(
          fill.resolve(pressed),
          isNot(rest),
          reason: '${entry.key}: press does not darken',
        );
        expect(
          fill.resolve(pressed),
          isNot(fill.resolve(hovered)),
          reason: '${entry.key}: press and hover are the same colour',
        );
      }
    });

    test('disabled resolves to the solid token, never to Material', () {
      for (final entry in themes.entries) {
        final semantic = entry.value.extension<AppSemanticColors>()!;
        final style = entry.value.filledButtonTheme.style!;

        expect(
          style.backgroundColor!.resolve(disabled),
          semantic.disabledSurface,
        );
        expect(style.foregroundColor!.resolve(disabled), semantic.onDisabled);
      }
    });
  });

  group('the outlined button', () {
    test('focus swaps the hairline for the ring without changing geometry', () {
      for (final entry in themes.entries) {
        final side = entry.value.outlinedButtonTheme.style!.side!;

        expect(side.resolve(focused)!.width, AppStroke.focus);
        expect(side.resolve(resting)!.width, AppStroke.hairline);
        expect(
          side.resolve(focused)!.color,
          isNot(side.resolve(resting)!.color),
          reason: '${entry.key}: the ring is the same colour as the hairline',
        );
      }
    });

    test('disabled draws the disabled solid, not a translucent tint', () {
      for (final entry in themes.entries) {
        final semantic = entry.value.extension<AppSemanticColors>()!;
        final side = entry.value.outlinedButtonTheme.style!.side!;

        expect(side.resolve(disabled)!.color, semantic.disabledSurface);
        expect(
          entry.value.outlinedButtonTheme.style!.foregroundColor!.resolve(
            disabled,
          ),
          semantic.onDisabled,
        );
      }
    });
  });

  group('the icon button', () {
    test('hover, press and focus all resolve rather than falling through', () {
      for (final entry in themes.entries) {
        final style = entry.value.iconButtonTheme.style!;
        final overlay = style.overlayColor!;

        expect(overlay.resolve(hovered), isNotNull, reason: entry.key);
        expect(overlay.resolve(pressed), isNotNull, reason: entry.key);
        expect(overlay.resolve(focused), isNotNull, reason: entry.key);
        expect(
          overlay.resolve(resting),
          isNull,
          reason: '${entry.key}: a resting control must paint no state layer',
        );
      }
    });

    test('focus draws the common ring and nothing else does', () {
      for (final entry in themes.entries) {
        final side = entry.value.iconButtonTheme.style!.side!;

        expect(side.resolve(focused)!.width, AppStroke.focus);
        expect(side.resolve(resting), isNull, reason: entry.key);
        expect(side.resolve(hovered), isNull, reason: entry.key);
      }
    });

    test('the disabled glyph is the shared token', () {
      for (final entry in themes.entries) {
        final semantic = entry.value.extension<AppSemanticColors>()!;

        expect(
          entry.value.iconButtonTheme.style!.foregroundColor!.resolve(disabled),
          semantic.onDisabled,
        );
      }
    });
  });

  group('the text button', () {
    test('hover and press blend the label toward the ink', () {
      for (final entry in themes.entries) {
        final semantic = entry.value.extension<AppSemanticColors>()!;
        final foreground = entry.value.textButtonTheme.style!.foregroundColor!;
        final rest = foreground.resolve(resting);

        expect(rest, entry.value.colorScheme.primary, reason: entry.key);
        expect(
          foreground.resolve(hovered),
          isNot(rest),
          reason: '${entry.key}: hover is invisible on the label',
        );
        expect(
          foreground.resolve(pressed),
          isNot(rest),
          reason: '${entry.key}: press does not deepen',
        );
        expect(
          foreground.resolve(pressed),
          isNot(foreground.resolve(hovered)),
          reason: '${entry.key}: press and hover are the same colour',
        );
        expect(
          foreground.resolve(disabled),
          semantic.onDisabled,
          reason: entry.key,
        );
      }
    });

    test('the icon rides the label through every state', () {
      // A glyph that keeps the resting colour while the label blends makes the
      // two halves of one control disagree about what state it is in.
      for (final entry in themes.entries) {
        final style = entry.value.textButtonTheme.style!;

        for (final states in <Set<WidgetState>>[
          resting,
          hovered,
          pressed,
          disabled,
        ]) {
          expect(
            style.iconColor!.resolve(states),
            style.foregroundColor!.resolve(states),
            reason: entry.key,
          );
        }
      }
    });

    test('the link paints no overlay and keeps the floor as height', () {
      for (final entry in themes.entries) {
        final style = entry.value.textButtonTheme.style!;

        expect(
          style.overlayColor!.resolve(hovered),
          Colors.transparent,
          reason:
              '${entry.key}: the states live on the text, not on a wash '
              'painted behind it',
        );
        expect(style.padding!.resolve(resting), EdgeInsets.zero);
        expect(
          style.minimumSize!.resolve(resting),
          const Size(0, AppSizing.touchTarget),
          reason: '${entry.key}: flush width, floor height',
        );
      }
    });

    test('destructive is the same resolver with danger as its accent', () {
      for (final entry in themes.entries) {
        final semantic = entry.value.extension<AppSemanticColors>()!;
        final foreground = textLinkForeground(
          entry.value.colorScheme,
          semantic,
          accent: semantic.danger,
        );

        expect(foreground.resolve(resting), semantic.danger, reason: entry.key);
        expect(
          foreground.resolve(disabled),
          semantic.onDisabled,
          reason: '${entry.key}: disabled wins over destructive',
        );
      }
    });
  });

  group('the radio', () {
    const selected = <WidgetState>{WidgetState.selected};

    test('selected, resting and disabled each declare their fill', () {
      for (final entry in themes.entries) {
        final semantic = entry.value.extension<AppSemanticColors>()!;
        final fill = entry.value.radioTheme.fillColor!;

        expect(
          fill.resolve(selected),
          entry.value.colorScheme.primary,
          reason:
              '${entry.key}: the mark is a glyph, so selected takes the '
              'accent — primary is a fill colour and misses 3:1 on the dark '
              'card',
        );
        expect(
          fill.resolve(resting),
          entry.value.colorScheme.onSurfaceVariant,
          reason: '${entry.key}: the resting ring is the quiet-glyph ink',
        );
        expect(
          fill.resolve(disabled),
          semantic.onDisabled,
          reason: '${entry.key}: disabled is the shared content token',
        );
      }
    });

    test('hover, press and focus resolve rather than falling through', () {
      for (final entry in themes.entries) {
        final overlay = entry.value.radioTheme.overlayColor!;

        expect(overlay.resolve(hovered), isNotNull, reason: entry.key);
        expect(overlay.resolve(pressed), isNotNull, reason: entry.key);
        expect(overlay.resolve(focused), isNotNull, reason: entry.key);
        expect(
          overlay.resolve(resting),
          isNull,
          reason: '${entry.key}: a resting control must paint no state layer',
        );
      }
    });
  });

  group('the four control shapes', () {
    test(
      'press wins over hover, because a pressed control is also hovered',
      () {
        // Ordering inside the resolver. Read hover first and every press in the
        // app renders as a hover — the heavier state would never be seen.
        for (final entry in themes.entries) {
          final overlay = AppInteractionStates.cardOverlay(
            entry.value.colorScheme,
          );

          expect(
            overlay.resolve(const <WidgetState>{
              WidgetState.hovered,
              WidgetState.pressed,
            }),
            overlay.resolve(pressed),
            reason: entry.key,
          );
        }
      },
    );

    test('a card hovers lighter than a row, and a row lighter than an icon', () {
      // The kit gives four weights on purpose: the same wash reads heavier on a
      // full-width row than on a 48-wide button. Compared by alpha, which is
      // what makes them different.
      final scheme = themes['light']!.colorScheme;

      expect(
        AppInteractionStates.cardOverlay(scheme).resolve(hovered)!.a,
        lessThan(AppInteractionStates.rowOverlay(scheme).resolve(hovered)!.a),
      );
      expect(
        AppInteractionStates.rowOverlay(scheme).resolve(hovered)!.a,
        lessThan(AppInteractionStates.iconOverlay(scheme).resolve(hovered)!.a),
      );
    });
  });

  group('strokes come from the token', () {
    test('an input keeps the input stroke in every state', () {
      for (final entry in themes.entries) {
        final input = entry.value.inputDecorationTheme;

        for (final border in <(String, InputBorder?)>[
          ('enabled', input.enabledBorder),
          ('focused', input.focusedBorder),
          ('error', input.errorBorder),
          ('focusedError', input.focusedErrorBorder),
          ('disabled', input.disabledBorder),
        ]) {
          expect(
            border.$2!.borderSide.width,
            AppStroke.input,
            reason: '${entry.key}: the ${border.$1} border left the token',
          );
        }
      }
    });

    test('a divider is one hairline tall and reserves nothing else', () {
      for (final entry in themes.entries) {
        expect(entry.value.dividerTheme.thickness, AppStroke.hairline);
        expect(
          entry.value.dividerTheme.space,
          AppStroke.hairline,
          reason: '${entry.key}: the divider reserves padding around itself',
        );
      }
    });

    test('the tooltip delay is the named one', () {
      for (final entry in themes.entries) {
        expect(entry.value.tooltipTheme.waitDuration, kTooltipWaitDuration);
      }
    });
  });
}
