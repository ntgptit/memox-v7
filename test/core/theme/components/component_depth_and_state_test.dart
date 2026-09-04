import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../../support/color_math.dart';

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
              'In ${entry.key}, the selected label sits on `selectedTileColor` '
              '— `surfaceSelected` since M100.36 — not on the page. The old '
              'dark fill tone measured 2.45:1 there; tone-80 `primary` clears '
              'it, and the retired `primaryAccent` no longer stands in.',
        );
        // The fill is the one app-owned "picked" surface, shared with the
        // card's tint (M100.36 4I) — two fills for one meaning was #431 P1-4.
        expect(tile.selectedTileColor, semanticsOf(theme).surfaceSelected);
      }
    });

    test('the theme sets no textColor, so the subtitle keeps its own ink', () {
      // `ListTile` copies a non-null `textColor` onto the title, the subtitle
      // and the leading/trailing text alike (`list_tile.dart:920`, `:934`,
      // `:899` at 3.44.8). A tautology stood here until M100.36; this is the
      // assertion the row system actually needed (#431 P1-1).
      for (final entry in themes.entries) {
        final tile = entry.value.listTileTheme;
        final scheme = entry.value.colorScheme;

        expect(tile.textColor, isNull, reason: entry.key);
        expect(tile.titleTextStyle?.color, scheme.onSurface, reason: entry.key);
        expect(
          tile.subtitleTextStyle?.color,
          scheme.onSurfaceVariant,
          reason: entry.key,
        );
        expect(
          tile.leadingAndTrailingTextStyle?.fontSize,
          entry.value.textTheme.bodyMedium?.fontSize,
          reason: '${entry.key}: trailing text fell back to label-sm 11px',
        );
      }
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
    // **The floor here used to be `cardOffPageFloor` — 7.7 L* — and dropping it
    // was the decision, not an accident (M100.20).** That number is the lift of
    // a *card off its page*; applying it to a *menu over a card* was this
    // repo's own extension, and no rung of an M3 container ladder is that far
    // from its neighbour. Material puts a menu on `surfaceContainer`, one step
    // above `surface`, and that step measures 3.50 L* in dark.
    //
    // The defect this group was written for survives intact, and it was never
    // "the step is small": it was that the menu drew `surface` on `surface` at
    // elevation 0 — **0.00 L\***, the same plane, with a 1.46:1 hairline as the
    // only sign a second layer had appeared. So the assertion is that the menu
    // sits on a *different rung*, which is what M3 guarantees and what the old
    // binding did not.
    //
    // The owner took this over the alternative — re-spacing the whole dark
    // container ladder so `surfaceContainer` cleared 7.7 — which would have
    // lightened every dark surface above `surface` to satisfy a target M3 does
    // not set.
    test('a menu opens on a different rung than the surface under it', () {
      for (final entry in themes.entries) {
        final theme = entry.value;
        final popup = theme.popupMenuTheme;
        final under = theme.colorScheme.surface;

        expect(
          popup.color,
          theme.colorScheme.surfaceContainer,
          reason:
              '${entry.key}: the menu left the M3 role, which is the only '
              'thing keeping it off the card its own ladder step provides',
        );
        expect(
          (lightnessStar(popup.color!) - lightnessStar(under)).abs(),
          greaterThan(0),
          reason:
              '${entry.key}: the menu and the card behind it resolved to the '
              'same plane, which is the defect this group exists for',
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

  group('every floating surface names its shadow colour', () {
    // **A20.1 P1-12.** `materialShadowColor` — `scheme.shadow` in light,
    // transparent in dark — was wired on two of the four themes that state a
    // non-zero elevation. This loop is the invariant, stated for every slot
    // the SDK offers, and the one slot it does not offer is pinned as a named
    // exemption rather than left to silence.
    test('the FAB, the card and the menu — dark transparent, light shadow', () {
      for (final entry in themes.entries) {
        final theme = entry.value;
        final isDark = theme.brightness == Brightness.dark;
        final Color expected = isDark
            ? Colors.transparent
            : theme.colorScheme.shadow;

        // The FAB reads `ThemeData.shadowColor` (`button.dart:387`), the only
        // route to its `Material`.
        expect(theme.shadowColor, expected, reason: '${entry.key}: FAB');
        expect(
          theme.floatingActionButtonTheme.elevation,
          greaterThan(0),
          reason: '${entry.key}: the FAB floats',
        );
        expect(
          theme.cardTheme.shadowColor,
          expected,
          reason: '${entry.key}: card',
        );
        expect(
          theme.popupMenuTheme.shadowColor,
          expected,
          reason: '${entry.key}: menu',
        );
      }
    });

    test('the snack bar is the one exemption, and it is named', () {
      // `SnackBarThemeData` has no `shadowColor`; `snack_bar.dart` builds a
      // bare `Material`, which in M3 shadows with `colorScheme.shadow`
      // (`material.dart:465`). Its dark shadow is `#03040B` on a page at
      // L* 4.1 — invisible by the same measurement `materialShadowColor`
      // encodes. Pinned here so the exemption cannot quietly grow: the level
      // still travels in both modes, and the SDK is still the reason.
      expect(
        themes['light']!.snackBarTheme.elevation,
        themes['dark']!.snackBarTheme.elevation,
      );
      expect(themes['dark']!.snackBarTheme.elevation, greaterThan(0));
      expect(
        lightnessStar(themes['dark']!.colorScheme.shadow),
        lessThan(lightnessStar(themes['dark']!.colorScheme.surface)),
        reason: 'the dark shadow must sit below the page it cannot show on',
      );
    });
  });
}
