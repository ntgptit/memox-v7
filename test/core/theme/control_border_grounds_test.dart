import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../support/color_math.dart';

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
  ];

  group('a control edge clears 3:1 on every ground it is drawn on', () {
    for (final entry in themes.entries) {
      final theme = entry.value;
      final semantic = semanticOf(theme);

      for (final ground in groundsOf(theme)) {
        test('${entry.key} · borderControl on ${ground.$1}', () {
          expect(
            contrast(semantic.borderControl, ground.$2),
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
    test(
      'the brand mark is `primary`, and reads on the page in both modes',
      () {
        // **This used to assert that `primaryAccent` outranked `primary` in
        // dark**, which was true while dark `primary` was a tone-40 fill that
        // measured 3.33:1 as bare text. M100.18 inverted it to tone 80, so the
        // brand hue reads as a mark on its own and the accent token is a
        // derivation of it awaiting removal.
        //
        // What the milestone actually cared about survives, stated directly: a
        // brand mark has to clear the text floor on the page it is inked on.
        for (final entry in themes.entries) {
          final theme = entry.value;

          // `primaryInk` since M100.27 — the mark is the brand as ink, and the
          // fill role is Tokyo's `#5569FF` verbatim (3.96:1 on the light page).
          expect(
            contrast(
              theme.extension<AppSemanticColors>()!.primaryInk,
              theme.scaffoldBackgroundColor,
            ),
            greaterThanOrEqualTo(4.5),
            reason:
                '${entry.key}: the brand hue no longer reads as a label on the '
                'page, so MxEmptyState and MxActionSheet lose their mark',
          );
        }
      },
    );

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
