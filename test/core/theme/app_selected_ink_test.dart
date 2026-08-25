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

    test('they agree in light and part company in dark', () {
      // Stated so the *shape* of the relationship is pinned, not just its
      // values: a reader who finds them equal in light should find the reason
      // here rather than conclude one of them is redundant.
      expect(
        selectedInk(light.colorScheme),
        semanticOf(light).primaryAccent,
        reason: 'light: both resolve to the brand fill, by construction',
      );
      expect(
        selectedInk(dark.colorScheme),
        isNot(semanticOf(dark).primaryAccent),
        reason: 'dark: the grounds differ, so the inks do',
      );
    });

    test('merging onto the accent would fail the pill in dark', () {
      // The measurement that refuses the merge. `primaryAccent` in dark is the
      // focus ring's brighter indigo, held there to stay recognisably *brand*
      // on a page — and on the selected pill's own fill it lands under the bar
      // a 12px label needs. If the palette ever moves so that this passes, the
      // two tokens can be reconsidered — but reconsidered, not merged on the
      // assumption that equal-in-light means equal.
      final fill = dark.chipTheme.color!.resolve(const <WidgetState>{
        WidgetState.selected,
      })!;

      expect(
        contrast(semanticOf(dark).primaryAccent, fill),
        lessThan(textFloor),
        reason:
            'the accent now clears 4.5:1 on the selected pill in dark, so '
            'selectedInk may no longer need to exist',
      );
    });

    test('each mode states its derivation rather than a hex', () {
      // The other direction of the merge fails a different test than
      // contrast: `onPrimaryContainer` in light is a near-black navy that
      // reads as body text, not as the brand the owner's mockup asks for
      // (2026-08-20). That judgement is not a number, so what is asserted
      // instead is the derivation — light takes the brand fill, dark takes the
      // M3 partner of the ground it prints on. Repointing either at a colour
      // that merely passes contrast now has to fail here first.
      expect(selectedInk(light.colorScheme), light.colorScheme.primary);
      expect(
        selectedInk(dark.colorScheme),
        dark.colorScheme.onPrimaryContainer,
      );
    });
  });
}
