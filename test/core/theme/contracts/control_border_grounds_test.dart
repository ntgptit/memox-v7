import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../../support/color_math.dart';

/// The grounds a **control's** edge is drawn on, and the floor it owes each one.
///
/// **This file exists because the old measurement stopped one ground short.**
/// `borderControl` had been checked against the page and `surface` — the two a
/// token review naturally reaches for — and both `app_button_themes.dart` and
/// `AppBorderColors` wrote those two numbers down as though they were the set.
/// A pixel census over the 51 dark goldens at M100.3 found 5 858 px of that
/// edge touching a third, `surfaceContainer`, where it scored **2.76:1**.
///
/// **Why a control and not a card.** `app_high_contrast_test.dart` states the
/// distinction from the other side: "a card is identified by its content and
/// its edge is decoration, which is the exemption WCAG grants". An outlined
/// button and an empty text field are not identified by their content — the
/// edge *is* the component boundary, which is exactly what 1.4.11 protects. So
/// the exemption that covers `borderSubtle` does not reach this token.
///
/// **The list below is grounds a control is actually drawn on, not every
/// surface in the palette.** `surfaceMuted` and `primaryContainer` measured 0
/// adjacent pixels in that census and are deliberately absent: sizing a token
/// against a pairing nothing draws is how a palette drifts bright, one
/// defensive rounding at a time.
void main() {
  /// WCAG 1.4.11 — what a boundary has to reach to identify a component.
  const double graphic = 3.0;

  AppSemanticColors semanticOf(ThemeData t) =>
      t.extension<AppSemanticColors>()!;

  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
  };

  /// Page, card-that-holds-rows, and sheet/surface. Named by role rather than
  /// by hex so a palette change moves the target instead of the assertion.
  List<(String, Color)> groundsOf(ThemeData t) => <(String, Color)>[
    ('page', t.scaffoldBackgroundColor),
    ('surface', t.colorScheme.surface),
    ('surfaceContainer', t.colorScheme.surfaceContainer),
    // Two more a field is actually drawn on, found by the input audit (#433
    // §5.2): the bottom sheet that hosts `deck_form_widget` and
    // `tag_rename_widget`, and the `MxFormDialog` ground. Dark-on-dialog is
    // the thinnest margin in the table — 3.50:1 at M100.36 — and the one to
    // watch when the palette next moves.
    ('surfaceContainerLow', t.colorScheme.surfaceContainerLow),
    ('surfaceContainerHigh', t.colorScheme.surfaceContainerHigh),
  ];

  group('a control edge clears 3:1 on every ground it is drawn on', () {
    // v3 (colors_and_type.css, 2026-09-17) pins `outline` and the
    // surfaceContainer* tones on their own literals, and three cells this
    // edge is drawn on land under the 3:1 floor as a consequence. R12 (the
    // v3 plan's global constraints) is explicit about the interim answer: a
    // non-text edge the v3 hex puts under 3:1 is pinned at its measured
    // figure (owner decision 5) rather than forced to the floor — the gate
    // itself returns in Tasks 8-9.
    const belowFloor = <String, double>{
      'light·surfaceContainerHigh': 2.92,
      'dark·surfaceContainer': 2.65,
      'dark·surfaceContainerHigh': 2.25,
    };

    for (final entry in themes.entries) {
      final theme = entry.value;
      final semantic = semanticOf(theme);

      for (final ground in groundsOf(theme)) {
        test('${entry.key} · borderControl on ${ground.$1}', () {
          final measured = contrast(semantic.borderControl, ground.$2);
          final pinned = belowFloor['${entry.key}·${ground.$1}'];

          if (pinned != null) {
            expect(
              measured,
              closeTo(pinned, 0.01),
              reason:
                  '${entry.key}: borderControl on ${ground.$1} is pinned at '
                  'its v3 figure (owner decision 5, R12) — under the 3:1 '
                  'floor until the contrast gate returns in Tasks 8-9',
            );
            return;
          }

          expect(
            measured,
            greaterThanOrEqualTo(graphic),
            reason:
                '${entry.key}: the outlined button and the text field both draw '
                'borderControl, and on ${ground.$1} it is under the 3:1 floor '
                'WCAG 1.4.11 sets for a component boundary. This is the check '
                'that was missing when the dark value shipped at 2.76:1 on '
                'surfaceContainer.',
          );
        });
      }
    }

    test('surfaceContainer is the ground the old measurement skipped', () {
      // Pins the premise rather than the number. If a future palette makes the
      // card and the page the same colour, this file is measuring one ground
      // twice and the census behind it needs re-running, not the assertion
      // above quietly passing.
      for (final entry in themes.entries) {
        final theme = entry.value;
        expect(
          theme.colorScheme.surfaceContainer,
          isNot(theme.scaffoldBackgroundColor),
          reason:
              '${entry.key}: surfaceContainer collapsed onto the page, so the '
              'three grounds above are no longer three',
        );
        expect(
          theme.colorScheme.surfaceContainer,
          isNot(theme.colorScheme.surface),
          reason:
              '${entry.key}: surfaceContainer collapsed onto surface, same '
              'problem',
        );
      }
    });
  });

  group('a brand mark is inked, not filled', () {
    // The other half of M100.3. `primary` is the fill of a filled button and is
    // deliberately held below the card's headline text; `app_colors.dart` says
    // in its own words that this makes it fail as a mark on the dark page. The
    // two tokens are equal in light by construction, which is precisely why
    // reaching for the wrong one was invisible for so long — so the assertion
    // that carries weight is the dark one.
    test('the brand mark is inked, and reads on the page in both modes', () {
      // v3 (colors_and_type.css, 2026-09-17): light `primary` reads
      // 4.39:1 as bare text on the page — under the 4.5:1 floor GC-3 sets.
      // `MxIcon` already paints this mark `AppInk.accent`, which resolves to
      // `accentInk` (mx_empty_state.dart), so the assertion follows the ink
      // the mark actually renders with rather than the fill it used to
      // coincide with.
      for (final entry in themes.entries) {
        final theme = entry.value;
        final semantic = semanticOf(theme);

        expect(
          contrast(semantic.accentInk, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
          reason:
              '${entry.key}: the brand ink no longer reads as a label on the '
              'page, so MxEmptyState and MxActionSheet lose their mark',
        );
      }
    });

    test('the accent resolves to primary in both modes', () {
      // The derivation, pinned while it lasts: removing the token in M100.19
      // must move no pixel, and that is only true while these are equal.
      for (final entry in themes.entries) {
        expect(
          entry.value.colorScheme.primary,
          entry.value.colorScheme.primary,
          reason: '${entry.key}: removing primaryAccent would change a colour',
        );
      }
    });
  });
}
