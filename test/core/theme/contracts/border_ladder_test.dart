import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';

import '../../../support/color_math.dart';

/// The order the app's edges stand in, and what holds up the two surfaces that
/// stopped drawing one.
///
/// **This file is the ceiling `control_border_grounds_test.dart` never had.**
/// That file holds a *floor*: every ground a control edge is drawn on must
/// reach 3:1. A floor only ever asks whether a value is dark enough, and
/// `AppBorderColors.borderControlLight` says so in its own words — *"A contrast
/// test only ever asks whether a value is dark enough, so nothing objected."*
///
/// So nothing did. Between M100.22 and M100.48 the token drifted from 3.24:1 to
/// **4.81:1** on white with every test green, and what it cost was legible on
/// the Guess screen: five answer rows reading as five heavy form fields. M100.48
/// lowered it by hand to 4.05 and **added no guard**, which left the same door
/// open at a slightly lower number.
///
/// M100.62 measured what the hand-fix had missed. On a card the grey resting
/// edge stood at **4.05:1** against `borderOption`'s **3.27** — the edge that
/// means *nothing has happened* was louder than the edge that means *this is
/// selectable*, in both modes. The app states the rule it was breaking, in
/// prose, in the same file: *"A resting edge must be quieter than a selected
/// one."* Prose is not enforcement.
void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
  };

  AppSemanticColors semanticOf(ThemeData t) =>
      t.extension<AppSemanticColors>()!;

  group('the resting edges stand in one order', () {
    for (final entry in themes.entries) {
      final theme = entry.value;
      final semantic = semanticOf(theme);

      /// The ground every edge in this group is compared on. A ladder is only
      /// a ladder when its rungs are measured against the same thing — the
      /// M100.48 fix compared two tokens on two different grounds and read as
      /// ordered while it was not.
      final card = theme.colorScheme.surfaceContainerLow;

      test('${entry.key} · a resting edge is quieter than a selected one', () {
        final control = contrast(semantic.borderControl, card);
        final option = contrast(semantic.borderOption, card);
        final selected = contrast(semantic.borderSelected, card);

        expect(
          control,
          lessThan(selected),
          reason:
              '${entry.key}: the control edge reads '
              '${control.toStringAsFixed(2)}:1 on a card against the selected '
              "edge's ${selected.toStringAsFixed(2)}:1. A resting edge that "
              'out-shouts a picked one inverts the only ranking these tokens '
              'have.',
        );

        expect(
          option,
          lessThan(selected),
          reason:
              '${entry.key}: the option edge reads '
              '${option.toStringAsFixed(2)}:1 against the selected edge, so a '
              'picked option no longer wins its own row.',
        );

        expect(
          contrast(semantic.borderSubtle, card),
          lessThan(option),
          reason:
              '${entry.key}: the hairline that separates is louder than the '
              'edge that identifies. The ladder is upside down at the bottom.',
        );
      });
    }
  });

  group('what separates a study surface that draws no edge', () {
    /// Two widgets draw **no border at all** at rest since M100.63 — the Guess
    /// answer row and the Match tile — after the owner compared all three
    /// treatments on a rendered golden and chose this one.
    ///
    /// That decision moved them from "a control that owes 1.4.11 a 3:1
    /// boundary" to "a card identified by its content", which is the exemption
    /// `app_high_contrast_test.dart` states from the other side. The exemption
    /// is legitimate and it is also the whole risk: with the edge gone, the
    /// **only** thing separating either surface from what is behind it is the
    /// depth `AppElevation.card` paints — a soft shadow in light, a zero-blur
    /// `outlineVariant` rim in dark.
    ///
    /// Measured on the committed goldens: **1.394:1** light and **1.298:1**
    /// dark for the row, **1.408:1** and **1.298:1** for the tile.
    /// Take the depth away and both fall to the bare fill step — **1.09:1** —
    /// and no contrast test in this repo would notice, because every one of
    /// them measures a *token* and there would no longer be a token to measure.
    ///
    /// So this replaces the licence check M100.62 put here. That one pinned
    /// which token the edge used; there is no edge now, and the thing worth
    /// pinning is that the replacement mechanism is still present.
    const sources = <String>[
      'lib/features/study/presentation/widgets/items/'
          'guess_option_item_widget.dart',
      'lib/features/study/presentation/widgets/items/match_tile_widget.dart',
    ];

    test('both still carry the depth that replaced their edge', () {
      for (final path in sources) {
        final source = File(path).readAsStringSync();

        expect(
          source.contains('AppElevation.card'),
          isTrue,
          reason:
              '$path no longer asks for AppElevation.card. Since M100.63 it '
              'draws no resting edge, so that depth is the only thing between '
              'its surface and the board: without it the separation is the '
              'bare fill step, 1.09:1.',
        );

        expect(
          source.contains('shadowsFor('),
          isTrue,
          reason:
              '$path names an elevation but never paints it. An elevation that '
              'reaches no BoxDecoration is a number, not a depth cue.',
        );
      }
    });

    test(
      'the fill alone is not enough, which is why the depth is load-bearing',
      () {
        // Pins the premise rather than the prose. If a palette move ever makes a
        // study surface step far enough off its ground to stand on its own, this
        // failing is the signal to re-derive the decision above rather than to
        // keep asserting a mechanism nothing needs.
        for (final entry in themes.entries) {
          final theme = entry.value;
          final measured = contrast(
            theme.colorScheme.surfaceContainerLow,
            theme.scaffoldBackgroundColor,
          );

          expect(
            measured,
            lessThan(1.5),
            reason:
                '${entry.key}: surfaceContainerLow now reads '
                '${measured.toStringAsFixed(2)}:1 against the page on its own. '
                'The borderless study surfaces were argued on the basis that it '
                'does not, so that argument needs re-reading.',
          );
        }
      },
    );
  });
}
