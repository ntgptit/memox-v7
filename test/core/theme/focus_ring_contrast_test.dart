import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_interaction_states.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../support/color_math.dart';

/// **A focus ring is a graphic, and WCAG 1.4.11 asks 3:1 of it.**
///
/// The project already applies that number — it is the argument in
/// `iconButtonTheme` for drawing a ring at all, and the argument that moved the
/// progress indicator off `primary` in M4.10m. It had never been applied to the
/// ring's own colour.
///
/// Three components drew `BorderSide(color: scheme.primary, width: 2)`. In light
/// that is fine. In dark `primary` is held at a luminance that keeps a filled
/// button from becoming the brightest thing on a navy page, so it measures
/// **2.90:1** on `surface` and **2.11:1** on `secondaryContainer` — a focus
/// indicator that marks the focused control for people who can already see
/// where they are.
///
/// **Measured against the grounds the ring actually sits on, not against one
/// nominal background.** A pill's ring is drawn on `secondaryContainer` when the
/// pill is selected, which is the darkest of the three and where `primary`
/// failed worst; a `surface`-only assertion would have passed and missed it.
void main() {
  /// WCAG 1.4.11 for a non-text graphic.
  const double graphicFloor = 3;

  for (final (String mode, ThemeData Function() build)
      in <(String, ThemeData Function())>[
        ('light', buildLightTheme),
        ('dark', buildDarkTheme),
      ]) {
    group('$mode focus ring', () {
      final ThemeData theme = build();
      final ColorScheme scheme = theme.colorScheme;
      final AppSemanticColors semantic = theme.extension<AppSemanticColors>()!;

      /// Every ground a focused control is drawn on.
      ///
      /// `background` is the page an icon button or an unselected pill sits
      /// straight on; `surface` is a card or a sheet; `secondaryContainer` is a
      /// selected pill's own fill. A ring has to clear the floor on all three,
      /// because which one it lands on is the screen's choice, not the theme's.
      final grounds = <String, Color>{
        'background': theme.scaffoldBackgroundColor,
        'surface': scheme.surface,
        'surfaceContainerHighest': scheme.surfaceContainerHighest,
        'secondaryContainer': scheme.secondaryContainer,
      };

      test('clears 3:1 on every ground it can land on', () {
        final ring = AppInteractionStates.focusRing(semantic).color;

        for (final entry in grounds.entries) {
          expect(
            contrast(ring, entry.value),
            greaterThanOrEqualTo(graphicFloor),
            reason:
                'the focus ring measures '
                '${contrast(ring, entry.value).toStringAsFixed(2)}:1 on '
                '${entry.key} in $mode — under the 3:1 WCAG 1.4.11 asks of a '
                'focus indicator',
          );
        }
      });

      test('is the reason the ring is not `primary`', () {
        // Kept as an assertion rather than a comment: it is the whole
        // justification for the token choice in `AppInteractionStates.focusRing`, and if the palette ever
        // moves `primary` up to where it would pass, this test says so instead
        // of quietly leaving a helper nobody can explain.
        //
        // Light passes on `primary` too, so only dark is asserted to fail.
        if (mode != 'dark') return;

        expect(
          contrast(scheme.primary, scheme.secondaryContainer),
          lessThan(graphicFloor),
          reason:
              'primary now clears 3:1 on secondaryContainer in dark. If that '
              'is deliberate, AppInteractionStates.focusRing can be reconsidered — but it must '
              'be reconsidered, not silently bypassed.',
        );
      });

      test('the three components that draw one all draw the same one', () {
        // The structural half. Equal colours today prove nothing about
        // tomorrow if each component computes its own, so this asserts they
        // resolve to the value `AppInteractionStates.focusRing` returns.
        final expected = AppInteractionStates.focusRing(semantic);

        final chip = (theme.chipTheme.side! as WidgetStateBorderSide).resolve(
          <WidgetState>{WidgetState.focused},
        );
        final outlined = theme.outlinedButtonTheme.style!.side!.resolve(
          <WidgetState>{WidgetState.focused},
        );
        final icon = theme.iconButtonTheme.style!.side!.resolve(<WidgetState>{
          WidgetState.focused,
        });

        for (final (String component, BorderSide? side)
            in <(String, BorderSide?)>[
              ('chip', chip),
              ('outlinedButton', outlined),
              ('iconButton', icon),
            ]) {
          expect(side, isNotNull, reason: '$component draws no focus ring');
          expect(
            side!.color,
            expected.color,
            reason: '$component draws its own focus colour in $mode',
          );
          expect(
            side.width,
            expected.width,
            reason: '$component draws its own focus width in $mode',
          );
        }
      });

      test('the ring is distinguishable from the resting border', () {
        // A ring that clears 3:1 against the page can still be invisible as a
        // *change* if it lands on the same colour the control already had.
        final ring = AppInteractionStates.focusRing(semantic).color;

        expect(
          ring,
          isNot(semantic.borderSubtle),
          reason: 'focus and rest draw the same border colour in $mode',
        );
      });
    });
  }
}
