import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_elevation.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../support/color_math.dart';

/// Three component decisions that a colour-role check cannot see.
///
/// Each of these was correct at the level the palette is asserted — every token
/// involved is derived from the seed, sits on the right rung, and passes on the
/// ground the palette test puts it on. They were wrong about **which** ground
/// the component actually paints them on, and that is a per-component fact.
///
/// So the assertions here name the pairing, not the colour: a selected label
/// against the tile it lands on, a resting border against the surface behind
/// the button, a menu against the card it opens over.
void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
  };

  AppSemanticColors semanticsOf(ThemeData theme) =>
      theme.extension<AppSemanticColors>()!;

  group('ListTile selected state', () {
    // The label is text, so 4.5:1 rather than 1.4.11's 3:1 for a state. With
    // `scheme.primary` dark measured 2.45 — it failed both thresholds.
    test('the selected label is readable on the selected tile', () {
      for (final entry in themes.entries) {
        final theme = entry.value;
        final tile = theme.listTileTheme;

        expect(
          contrast(tile.selectedColor!, tile.selectedTileColor!),
          greaterThanOrEqualTo(4.5),
          reason:
              'In ${entry.key}, the selected label sits on `selectedTileColor`, '
              'not on the page. `scheme.primary` measured 2.45:1 there in dark; '
              '`primaryAccent` is the variant derived for that ground.',
        );
      }
    });

    test('light is unchanged, because there the accent is the primary', () {
      final theme = themes['light']!;

      expect(
        theme.colorScheme.primary,
        theme.colorScheme.primary,
        reason:
            'The dark fix must not quietly restyle light. If these ever differ, '
            'the light selected row changed colour and nobody asked for it.',
      );
    });
  });

  group('OutlinedButton resting border', () {
    test('reads as a control boundary on every ground it is drawn on', () {
      for (final entry in themes.entries) {
        final theme = entry.value;
        final scheme = theme.colorScheme;
        final side = theme.outlinedButtonTheme.style!.side!.resolve(
          <WidgetState>{},
        )!;

        // The page, not `surfaceContainerLowest` — that rung is
        // `surfaceElevated` in light, so it would have measured the button
        // against a surface no screen puts it on.
        for (final ground in <(String, Color)>[
          ('surface', scheme.surface),
          ('page', theme.scaffoldBackgroundColor),
        ]) {
          expect(
            contrast(side.color, ground.$2),
            greaterThanOrEqualTo(3),
            reason:
                'In ${entry.key} on ${ground.$1}: WCAG 1.4.11 asks 3:1 of a '
                'control boundary. `borderSubtle` — the decorative edge, which '
                'is `outlineVariant` — gave 1.45 in light and 2.04 in dark.',
          );
        }
      }
    });

    test('it is the token the scheme already calls `outline`', () {
      for (final entry in themes.entries) {
        final theme = entry.value;
        final side = theme.outlinedButtonTheme.style!.side!.resolve(
          <WidgetState>{},
        )!;

        expect(
          side.color,
          semanticsOf(theme).borderControl,
          reason:
              'In ${entry.key}, `colorScheme.outline` maps to `borderControl`. '
              'The button reading a different token is an internal mismatch, '
              'not a considered deviation from Material.',
        );
        expect(side.color, theme.colorScheme.outline);
      }
    });
  });

  group('BottomSheet drag handle', () {
    // `_DragHandle` is `Semantics(button: true, onTap: …)` padded to
    // `kMinInteractiveDimension`, so it is a control and 1.4.11's 3:1 applies.
    // `borderSubtle` gave 1.45 and 2.04 on the sheet it sits on.
    test('reads as a control on the sheet it sits on', () {
      for (final entry in themes.entries) {
        final theme = entry.value;
        final handle = WidgetStateProperty.resolveAs<Color?>(
          theme.bottomSheetTheme.dragHandleColor,
          const <WidgetState>{},
        )!;

        expect(
          contrast(handle, theme.bottomSheetTheme.backgroundColor!),
          greaterThanOrEqualTo(3),
          reason:
              '${entry.key}: the handle is the only thing saying this sheet '
              'can be dragged or dismissed',
        );
      }
    });

    test('the grab is visible, and it is the state a phone can reach', () {
      for (final entry in themes.entries) {
        final Color? slot = entry.value.bottomSheetTheme.dragHandleColor;
        Color at(Set<WidgetState> states) =>
            WidgetStateProperty.resolveAs<Color?>(slot, states)!;

        final resting = at(const <WidgetState>{});
        final dragged = at(const <WidgetState>{WidgetState.dragged});

        expect(
          dragged,
          isNot(resting),
          reason:
              '${entry.key}: a plain `Color` in this slot swallows both states '
              'the SDK sets. Hover does not exist on a phone; the drag does.',
        );
        expect(
          at(const <WidgetState>{WidgetState.hovered}),
          dragged,
          reason: '${entry.key}: the two active states read the same',
        );
        expect(
          contrast(dragged, entry.value.bottomSheetTheme.backgroundColor!),
          greaterThan(
            contrast(resting, entry.value.bottomSheetTheme.backgroundColor!),
          ),
          reason: '${entry.key}: the handle must firm up, not soften',
        );
      }
    });
  });

  group('PopupMenu depth', () {
    // AD-14: depth is a measurable target, and the target this app already
    // holds is a card lifting off its page — 7.75 L* in light, 7.70 in dark. A
    // menu has no scrim, so it has to clear at least that off the card it
    // opens over, by whatever means its mode has.
    const double cardOffPageFloor = 7.7;

    test('a menu lifts off the surface it opens over', () {
      for (final entry in themes.entries) {
        final theme = entry.value;
        final popup = theme.popupMenuTheme;
        final under = theme.colorScheme.surface;

        final paperStep = (lightnessStar(popup.color!) - lightnessStar(under))
            .abs();
        final shadow = shadowsFor(popup.elevation!, theme.colorScheme);
        final shadowGain = shadow.isEmpty
            ? 0.0
            : (lightnessStar(under) -
                      lightnessStar(
                        Color.alphaBlend(shadow.single.color, under),
                      ))
                  .abs();

        expect(
          paperStep + shadowGain,
          greaterThanOrEqualTo(cardOffPageFloor),
          reason:
              'In ${entry.key} the menu lifts off the card beneath it by '
              '${(paperStep + shadowGain).toStringAsFixed(2)} L* '
              '(paper ${paperStep.toStringAsFixed(2)}, shadow '
              '${shadowGain.toStringAsFixed(2)}). On `surface` at elevation 0 '
              'this was 0.00 — the same plane — and a menu, unlike a dialog, '
              'has no scrim to separate it.',
        );
      }
    });

    test('the level travels in both modes; only the paint stops at dark', () {
      expect(
        themes['light']!.popupMenuTheme.elevation,
        themes['dark']!.popupMenuTheme.elevation,
        reason:
            'AD-14 keeps the scale and the paint apart. Dropping dark to 0 '
            'would say the menu is flush with what is behind it.',
      );

      expect(
        themes['dark']!.popupMenuTheme.shadowColor,
        Colors.transparent,
        reason:
            'A dark shadow is paint nobody can see — the dark page is at the '
            'bottom of the lightness scale. The paper step carries dark alone.',
      );
      expect(
        themes['light']!.popupMenuTheme.shadowColor,
        isNot(Colors.transparent),
        reason:
            "Light's ladder is compressed near white, so the shadow is the "
            'whole lift there — the paper step is worth 0.32 L*.',
      );
    });
  });
}
