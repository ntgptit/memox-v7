import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_interaction_states.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_stroke.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../support/color_math.dart';
import '../../support/theme_probe.dart';

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
///
/// **Two more groups cover the controls that cannot take the shared ring.** A
/// filled button's ground is the accent itself, so the ring token measures
/// 1.02:1 on it and the button draws its own label colour instead; a text
/// button has neither a border nor an overlay by design, so it underlines. Both
/// resolved to nothing before M99.43 — the app's primary call to action had no
/// focus-visible state at all — which is why their absence is now asserted
/// rather than left to the reader of a component list.
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

      test('the three surface-grounded components all draw the same one', () {
        // The structural half. Equal colours today prove nothing about
        // tomorrow if each component computes its own, so this asserts they
        // resolve to the value `AppInteractionStates.focusRing` returns.
        //
        // **The filled button is deliberately not in this list**, and its
        // absence is checked rather than assumed — see the `filled focus ring`
        // group below. These three sit on a page, a card or a pill's own fill,
        // where the token clears 3:1; the filled button sits on the accent,
        // where the same token measures 1.02:1.
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

    group('$mode filled focus ring', () {
      final ThemeData theme = build();
      final ColorScheme scheme = theme.colorScheme;
      final AppSemanticColors semantic = theme.extension<AppSemanticColors>()!;

      /// Every fill `buildFilledStyle` is applied to, with the label that
      /// travels with it — the primary CTA, `MxActionButton`'s destructive
      /// variant, and the tonal style the deck row's Study button uses.
      final variants = <String, (Color, Color)>{
        'primary': (filledButtonFill(theme), scheme.onPrimary),
        'error': (scheme.error, scheme.onError),
        'secondaryContainer': (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
        ),
      };

      test('a filled button draws a ring at all', () {
        // The regression this whole group exists for: the primary CTA of every
        // screen resolved `side` to nothing, and its only other focus signal
        // was a wash of `primary` on a `primary` fill.
        final side = filledButtonFocusSide(theme);

        expect(side, isNotNull, reason: 'filled button draws no focus ring');
        expect(side!.width, AppStroke.focus);
        expect(
          side.color,
          scheme.onPrimary,
          reason: 'the ring is the button label, not a separate token',
        );
      });

      test('and none at rest', () {
        // A filled button is a fill, not a fill inside a frame. If this starts
        // returning a side, focus has stopped being a *change*.
        expect(
          theme.filledButtonTheme.style!.side!.resolve(const <WidgetState>{}),
          isNull,
        );
      });

      test('the ring clears 3:1 on every fill it is drawn on', () {
        // The label of a filled button is already contrast-checked against its
        // own fill in `app_theme_test.dart`, at the 4.5 body-text bar. Stated
        // again here at the graphic bar, because that is the property the ring
        // depends on and it must not be able to change silently underneath it.
        for (final entry in variants.entries) {
          expect(
            contrast(entry.value.$2, entry.value.$1),
            greaterThanOrEqualTo(graphicFloor),
            reason: '$mode: the ring on the ${entry.key} fill',
          );
        }
      });

      test('the shared ring token would be invisible here', () {
        // Records the reason for the deviation, the way the `focusRing` doc
        // comment records its own. If the palette ever moves so that this
        // passes, `focusRingOf(label)` can be reconsidered — but it must be
        // reconsidered, not silently bypassed.
        expect(
          contrast(semantic.focusRing, filledButtonFill(theme)),
          lessThan(graphicFloor),
          reason:
              'the ring token now clears the floor on the accent fill, so the '
              'filled button no longer needs a ring of its own',
        );
      });

      test('the focus wash alone changes nothing, which is why', () {
        // The other half of the reason. `controlOverlay` resolves focus to
        // `primary` at 10%, and the fill it lands on IS `primary` — so the
        // overlay composites to the colour it started from. Pinned so that a
        // future "the wash is enough, drop the ring" reads this number first.
        final fill = filledButtonFill(theme);
        final overlay = theme.filledButtonTheme.style!.overlayColor!.resolve(
          const <WidgetState>{WidgetState.focused},
        )!;

        expect(
          contrast(Color.alphaBlend(overlay, fill), fill),
          lessThan(1.1),
          reason: '$mode: the focus wash is a visible change on its own',
        );
      });
    });

    group('$mode text button focus', () {
      final ThemeData theme = build();
      final WidgetStateProperty<TextStyle?> textStyle =
          theme.textButtonTheme.style!.textStyle!;

      test('a rule under the label, at the focus stroke', () {
        // The link has no border to thicken and no overlay to wash — both are
        // deliberate — so the underline is the whole indicator. `MxTextButton`
        // already drew it; this pins that a bare `TextButton` does too.
        final focused = textStyle.resolve(const <WidgetState>{
          WidgetState.focused,
        });

        expect(focused?.decoration, TextDecoration.underline);
        expect(focused?.decorationThickness, AppStroke.focus);
      });

      test('and no rule at rest', () {
        expect(
          textStyle.resolve(const <WidgetState>{})?.decoration,
          isNot(TextDecoration.underline),
        );
      });

      test('the rung survives being restated', () {
        // `ButtonStyle.textStyle` is taken wholesale rather than merged, so a
        // partial style here would silently drop `labelLarge`'s size, leading
        // and tracking on the way past `TextButton.defaultStyleOf`.
        final rung = theme.textTheme.labelLarge;

        for (final states in <Set<WidgetState>>[
          const <WidgetState>{},
          const <WidgetState>{WidgetState.focused},
        ]) {
          final style = textStyle.resolve(states);

          expect(style?.fontSize, rung?.fontSize, reason: '$mode $states');
          expect(style?.height, rung?.height, reason: '$mode $states');
          expect(
            style?.letterSpacing,
            rung?.letterSpacing,
            reason: '$mode $states',
          );
          expect(style?.fontWeight, rung?.fontWeight, reason: '$mode $states');
        }
      });
    });
  }
}
