import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_material_roles.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../support/color_math.dart';

/// **Two inks that look like one, and the measurements that keep them apart.**
///
/// `AppSemanticColors.primaryAccent` is the brand hue as a label on a surface —
/// a link, an accent glyph on a card. `AppMaterialRoles.selectedInk` is the ink
/// of a control that is *selected*, whose ground is the selection's own tint.
/// In light both resolve to `primary`, which is exactly why they read as two
/// spellings of one idea and why one of them kept getting proposed for
/// deletion.
///
/// They cannot merge, in either direction, and the numbers below are the
/// reason. Every ground is read off the built theme rather than off a token,
/// because what a reader sees is the colour the component resolved — the same
/// rule `theme_probe.dart` exists for.
void main() {
  /// WCAG AA for the 12px label a pill and a tab both print.
  const double textFloor = 4.5;

  for (final (String mode, ThemeData Function() build)
      in <(String, ThemeData Function())>[
        ('light', buildLightTheme),
        ('dark', buildDarkTheme),
      ]) {
    group('$mode selected ink', () {
      final ThemeData theme = build();
      final ColorScheme scheme = theme.colorScheme;

      /// Every ground a selected control prints its ink on.
      ///
      /// The navigation bar splits: M3 draws the active icon inside the
      /// indicator pill and the label *below* it, on the bar itself. One token
      /// therefore has to clear the floor on two different colours, which is
      /// the fact a single `surface`-shaped assertion would have missed.
      final grounds = <String, Color>{
        'the selected pill fill': theme.chipTheme.color!.resolve(
          const <WidgetState>{WidgetState.selected},
        )!,
        'the navigation indicator': theme.navigationBarTheme.indicatorColor!,
        'the navigation bar itself': theme.navigationBarTheme.backgroundColor!,
      };

      test('clears 4.5:1 on every ground a selected control has', () {
        final ink = selectedInk(scheme);

        for (final entry in grounds.entries) {
          expect(
            contrast(ink, entry.value),
            greaterThanOrEqualTo(textFloor),
            reason:
                '$mode: the selected ink measures '
                '${contrast(ink, entry.value).toStringAsFixed(2)}:1 on '
                '${entry.key}',
          );
        }
      });

      test('the pill and the tab resolve the same ink', () {
        // Equal colours today prove nothing about tomorrow if each component
        // computes its own — the state this function was written to end.
        final expected = selectedInk(scheme);
        const selected = <WidgetState>{WidgetState.selected};

        expect(
          (theme.chipTheme.labelStyle!.color! as WidgetStateColor).resolve(
            selected,
          ),
          expected,
          reason: '$mode: the pill label',
        );
        expect(
          theme.navigationBarTheme.iconTheme!.resolve(selected)!.color,
          expected,
          reason: '$mode: the active tab glyph',
        );
        expect(
          theme.navigationBarTheme.labelTextStyle!.resolve(selected)!.color,
          expected,
          reason: '$mode: the active tab label',
        );
      });
    });
  }

  group('selected ink versus the accent', () {
    final ThemeData light = buildLightTheme();
    final ThemeData dark = buildDarkTheme();

    AppSemanticColors semanticOf(ThemeData theme) =>
        theme.extension<AppSemanticColors>()!;

    test('the selected ink is `onPrimaryContainer`, in both modes', () {
      // **The M3 pair, and now the only reason the two tokens differ.** This
      // group used to pin a brightness switch: `primary` in light, the M3
      // partner in dark, because dark `primary` landed at 2.13:1 on the pill.
      // M100.18 inverted the dark accent, so the switch had no ratio left to
      // justify it and the ink became one role — the one Material names for a
      // label printed on a container fill.
      for (final entry in <String, ThemeData>{
        'light': light,
        'dark': dark,
      }.entries) {
        expect(
          selectedInk(entry.value.colorScheme),
          entry.value.colorScheme.onPrimaryContainer,
          reason:
              '${entry.key}: the selected ink drifted off the M3 pair for a '
              'label on a container',
        );
      }
    });

    test('the accent would now pass too, so the choice is semantic', () {
      // **The honest statement of what changed.** Merging the selected ink
      // onto the brand accent used to be refused by a measurement — it landed
      // under 4.5:1 on the pill in dark. It no longer does, in either mode. So
      // the separation survives on the rule rather than on the number: a label
      // on `primaryContainer` takes `onPrimaryContainer`, and a brand mark on
      // a surface takes `primary`. Same grammar, different grounds.
      //
      // Asserted rather than written down, because a number that stopped
      // forcing a decision is exactly the kind that gets quietly re-cited.
      for (final entry in <String, ThemeData>{
        'light': light,
        'dark': dark,
      }.entries) {
        final fill = entry.value.chipTheme.color!.resolve(const <WidgetState>{
          WidgetState.selected,
        })!;

        expect(
          contrast(semanticOf(entry.value).primaryAccent, fill),
          greaterThanOrEqualTo(textFloor),
          reason:
              '${entry.key}: the accent no longer clears 4.5:1 on the selected '
              'pill, so the separation is forced again and this test should '
              'say which measurement forces it',
        );
      }
    });
  });
}
