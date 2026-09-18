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
    // **The 3:1 is no longer met, and this records it** (M100.101). v3 gives
    // the outlined button the chip's edge — `outlineVariant` — which reads
    // **1.53:1** on the page in light and **1.58:1** in dark, where `outline`
    // read 3.44 and 3.75. WCAG 1.4.11 asks 3:1 of a control boundary; the
    // owner chose v3 with those figures in hand.
    //
    // The button is the *least* harmed of the three edges v3 moved, because it
    // keeps a label inside it: a bare text field does not, which is why
    // `control_border_grounds_test.dart` carries the fuller record.
    //
    // Pinned as an intermediate-state record: a further drop still fails, and
    // what would restore the floor is a darker `outlineVariant` or a return to
    // `outline` for this component.
    const double pinnedLight = 1.53;
    const double pinnedDark = 1.58;

    test('is pinned where v3 left it, below the 3:1 a control owes', () {
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
            greaterThanOrEqualTo(
              entry.key == 'light' ? pinnedLight : pinnedDark,
            ),
            reason:
                'In ${entry.key} on ${ground.$1}: the edge is already below '
                'the 3:1 WCAG 1.4.11 asks of a control boundary — it must not '
                'get quieter still',
          );
        }
      }
    });

    test('it is the token the scheme calls `outlineVariant`', () {
      for (final entry in themes.entries) {
        final theme = entry.value;
        final side = theme.outlinedButtonTheme.style!.side!.resolve(
          <WidgetState>{},
        )!;

        // It used to be `borderControl` (`colorScheme.outline`). v3 moved it
        // to the chip's edge, so the assertion moves with it — what the test
        // still guards is that the button reads *a named role* rather than a
        // literal someone typed.
        expect(
          side.color,
          theme.colorScheme.outlineVariant,
          reason:
              'In ${entry.key}, the outlined button reads v3 outlineVariant '
              '(M100.101). A different value here is an internal mismatch, '
              'not a considered deviation.',
        );
      }
    });
  });

  group('BottomSheet drag handle', () {
    // `_DragHandle` is `Semantics(button: true, onTap: …)` padded to
    // `kMinInteractiveDimension`, so it is a control and 1.4.11's 3:1 applies.
    // `borderSubtle` gave 1.45 and 2.04 on the sheet it sits on.
    //
    // **The 3:1 floor is not being met, and this records that rather than
    // hiding it** (M100.99). v3 names `outlineVariant` for this slot and the
    // owner chose v3 over the floor with these figures in hand: on the sheet's
    // `surfaceContainerHigh` ground the handle reads **1.30:1 in light and
    // 1.05:1 in dark**, where `onSurfaceVariant` read 6.12 and 5.10. Dark is
    // `#2A3267` on `#2C356E` — a handle findable only by someone who already
    // knows it is there.
    //
    // So the assertion below is an **intermediate-state record**, not a
    // standard: it pins today's numbers so a further drop still fails, and it
    // names what would restore the floor — a different role for the slot, or a
    // sheet ground far enough from `outlineVariant` to carry it. Restoring the
    // 3:1 form is the sheet component task's to do; nothing here should be
    // read as saying 1.05:1 is adequate.
    const double pinnedLight = 1.30;
    const double pinnedDark = 1.05;

    test('is pinned where v3 left it, below the 3:1 a control owes', () {
      for (final entry in themes.entries) {
        final theme = entry.value;
        final handle = WidgetStateProperty.resolveAs<Color?>(
          theme.bottomSheetTheme.dragHandleColor,
          const <WidgetState>{},
        )!;

        expect(
          contrast(handle, theme.bottomSheetTheme.backgroundColor!),
          greaterThanOrEqualTo(entry.key == 'light' ? pinnedLight : pinnedDark),
          reason:
              '${entry.key}: the handle is the only thing saying this sheet '
              'can be dragged or dismissed, and it is already below the 3:1 '
              'a control owes — it must not get quieter still',
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

  group('NavigationBar selected ink', () {
    // **The v3 brand ink on the active tab, and the floor it does not meet**
    // (M100.100). `onSurface` gave 15.03:1 in light and 11.01:1 in dark on the
    // bar; `primary` gives 3.95:1 and 5.22:1. Small text owes 4.5:1, so light
    // is **under the floor** — on the one word that says which tab a user is
    // in. The owner chose v3 with that figure in hand.
    //
    // Pinned as an intermediate-state record, the same shape the bottom
    // sheet's grabber carries above: it blocks a further drop and names what
    // would close it — a darker `primary` for ink use, or a bar ground further
    // from it. It is not a statement that 3.95 is adequate.
    //
    // What still carries the selection when the colour does not: the
    // outlined/filled icon pair (no colour at all), the w600 weight, and
    // `Semantics(selected:)`.
    // Floored to two decimals, not rounded (R12): the light measurement is
    // 3.9485, which *rounds* to 3.95 and is below it. The prose above quotes
    // the rounded figure because that is how the number is discussed; the
    // assertion uses the floor so it cannot fail on its own reading.
    const double pinnedLabelLight = 3.94;
    const double pinnedLabelDark = 5.21;

    test('the label is pinned where v3 left it, under the 4.5 text owes', () {
      for (final entry in themes.entries) {
        final ThemeData theme = entry.value;
        final Color label = theme.navigationBarTheme.labelTextStyle!.resolve(
          const <WidgetState>{WidgetState.selected},
        )!.color!;

        expect(
          contrast(label, theme.navigationBarTheme.backgroundColor!),
          greaterThanOrEqualTo(
            entry.key == 'light' ? pinnedLabelLight : pinnedLabelDark,
          ),
          reason:
              '${entry.key}: the active tab label must not get quieter than '
              'v3 left it — light is already below the 4.5:1 small text owes',
        );
      }
    });

    test('the glyph clears the 3:1 a graphic owes, on the pill it sits in', () {
      for (final entry in themes.entries) {
        final ThemeData theme = entry.value;
        final Color glyph = theme.navigationBarTheme.iconTheme!.resolve(
          const <WidgetState>{WidgetState.selected},
        )!.color!;

        expect(
          contrast(glyph, theme.navigationBarTheme.indicatorColor!),
          greaterThanOrEqualTo(3),
          reason:
              '${entry.key}: the active glyph sits inside the indicator, so '
              'the pill is the ground it must separate from',
        );
      }
    });
  });
}
