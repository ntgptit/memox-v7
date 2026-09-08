import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';

import '../../../support/color_math.dart';

/// The order the app's edges stand in, and the licence that lets a study
/// surface wear the brand one.
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
  /// WCAG 1.4.11 — what a component boundary owes its ground.
  const double graphic = 3.0;

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

  group('the licence a study surface spends', () {
    /// Two widgets draw `borderOption` as a **control** boundary rather than as
    /// a card's decoration: the Guess answer row and the Match tile. Both are
    /// drawn on `surfaceContainerLow`, and that is not a detail — it is the
    /// whole permission.
    ///
    /// `borderOption` clears 3:1 on `surfaceContainerLow` and **on no other
    /// control ground**: at M100.62 it measured 2.99 on the page, 2.92 on
    /// `surfaceContainer` and 2.74 on `surfaceContainerHigh`. So the outlined
    /// button and the text field keep `borderControl`, and the two study
    /// surfaces are an exception with a measurement under it rather than a
    /// preference.
    ///
    /// If a palette move drops this pairing under the floor, those two widgets
    /// stop identifying themselves and nothing else in the suite would notice:
    /// `control_border_grounds_test.dart` measures the *other* token.
    for (final entry in themes.entries) {
      test('${entry.key} · the brand edge identifies a control on a card', () {
        final semantic = semanticOf(entry.value);
        final ground = entry.value.colorScheme.surfaceContainerLow;
        final measured = contrast(semantic.borderOption, ground);

        expect(
          measured,
          greaterThanOrEqualTo(graphic),
          reason:
              '${entry.key}: borderOption reads '
              '${measured.toStringAsFixed(2)}:1 on surfaceContainerLow, under '
              'the 3:1 WCAG 1.4.11 asks of a component boundary. The Guess row '
              'and the Match tile draw it as their only boundary, so this is '
              'the number that licenses them to use it instead of '
              'borderControl.',
        );
      });
    }

    test('both surfaces are still drawn on the ground that licensed them', () {
      // Pins the premise rather than the colour, the way
      // `control_border_grounds_test.dart` pins that its three grounds are
      // three. Moving either widget onto the page keeps every contrast test
      // green while voiding the exception above, because the assertion would
      // then be measuring a ground nothing draws.
      const sources = <String>[
        'lib/features/study/presentation/widgets/items/'
            'guess_option_item_widget.dart',
        'lib/features/study/presentation/widgets/items/match_tile_widget.dart',
      ];

      for (final path in sources) {
        final source = File(path).readAsStringSync();

        expect(
          source.contains('scheme.surfaceContainerLow'),
          isTrue,
          reason:
              '$path no longer names surfaceContainerLow as its ground. That '
              'is the only ground on which borderOption clears 3:1, so the '
              'exception this widget spends is void and its edge has to go '
              'back to borderControl — or the ground has to be re-measured.',
        );

        expect(
          source.contains('semantic.borderOption'),
          isTrue,
          reason:
              '$path stopped drawing borderOption. If that is deliberate, '
              'delete its entry here; if it is a revert to borderControl, the '
              'grey resting edge measured 4.05:1 on this ground and was the '
              'loudest resting line in the app (M100.62).',
        );
      }
    });
  });
}
