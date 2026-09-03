import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/components/actions/app_button_themes.dart';
import 'package:memox/core/theme/typography/app_typography.dart';

/// **`ThemeData.textTheme` being right is not the same as a component using it.**
///
/// `app_typography_test.dart` pins the scale that `Theme.of(context).textTheme`
/// resolves. Every component theme in `app_theme.dart` was built from
/// `base.textTheme` instead — Material 3's scale, taken from the `ThemeData` that
/// exists before `copyWith` replaces it. The families matched, so nothing looked
/// wrong; the weights did not.
///
/// Concretely, `labelLarge` is 600 in this app and 500 in Material's scale, so
/// the pill's label — the app's most repeated piece of UI text — rendered a
/// weight the design never asked for. `titleMedium` on a dialog had the same gap,
/// and the `fontVariations` that actually move a variable font's `wght` axis
/// reached none of them.
///
/// So this file asks the question the other one cannot: of the styles the
/// component themes *declare*, is each one the app's?
///
/// **The pill's weight later became 500 again, and the difference is the point.**
/// Then it was 500 because nobody had said anything and Material answered; now it
/// is 500 because `app_chip_theme.dart` declares it, carries the measurement, and
/// moves the `wght` axis with it. A value and a decision that happen to agree are
/// still not the same thing — [expectRungReweighted] is what tells them apart.
void main() {
  /// A style that came from [AppTypography] and one that did not are told apart
  /// by `fontVariations`. Material sets a `fontWeight` and stops there; this app
  /// sets both, because `fontWeight` alone does not reliably move a variable
  /// font's `wght` axis across renderers.
  ///
  /// Checking the family instead would pass on every one of these slots — the
  /// `ThemeData` those styles came from already had `fontFamily: Inter` on it,
  /// which is exactly why the gap survived a review.
  void expectAppStyle(String slot, TextStyle? style) {
    expect(style, isNotNull, reason: '$slot has no style');
    expect(
      style!.fontVariations,
      isNotEmpty,
      reason:
          '$slot carries no fontVariations, so it did not come through '
          'AppTypography.buildTextTheme — it is Material 3 scale wearing the '
          "app's font family",
    );
    expect(
      style.fontFamily,
      anyOf(AppTypography.bodyFamily, AppTypography.displayFamily),
      reason: '$slot is not set in one of the two app faces',
    );
  }

  /// The style [slot] must equal, ignoring the colour each component overrides.
  void expectSameRung(String slot, TextStyle? style, TextStyle? rung) {
    expectAppStyle(slot, style);
    expect(style!.fontSize, rung?.fontSize, reason: '$slot size');
    expect(style.fontWeight, rung?.fontWeight, reason: '$slot weight');
    expect(style.height, rung?.height, reason: '$slot leading');
    expect(style.letterSpacing, rung?.letterSpacing, reason: '$slot tracking');
    expect(
      style.fontVariations,
      rung?.fontVariations,
      reason: '$slot variable-font axis',
    );
  }

  /// Everything the rung decides, except the weight the component re-declares.
  ///
  /// The pill is the app's one rung-level exception, so this is deliberately not
  /// a general escape hatch: size, leading and tracking must still be the rung's,
  /// because the pill is `label-lg` *set lighter*, not a private style.
  ///
  /// **The `wght` assertion is the load-bearing one.** Both faces are variable
  /// fonts, and the renderer consults the axis instead of [TextStyle.fontWeight]
  /// once it is present — so a re-weight that moves only `fontWeight` reports the
  /// new value here and paints the old one on the device. Asserting the weight
  /// alone would pass on exactly the bug worth catching.
  void expectRungReweighted(
    String slot,
    TextStyle? style,
    TextStyle? rung,
    FontWeight weight,
  ) {
    expectAppStyle(slot, style);
    expect(style!.fontSize, rung?.fontSize, reason: '$slot size');
    expect(style.height, rung?.height, reason: '$slot leading');
    expect(style.letterSpacing, rung?.letterSpacing, reason: '$slot tracking');
    expect(style.fontWeight, weight, reason: '$slot weight');
    expect(
      style.fontVariations,
      <FontVariation>[FontVariation('wght', weight.value.toDouble())],
      reason:
          '$slot says $weight and its variable-font axis says otherwise, so it '
          'reports one weight and paints another',
    );
    expect(
      style.fontWeight,
      isNot(rung?.fontWeight),
      reason:
          '$slot no longer differs from the rung. If the rung moved to meet it, '
          'the exception is now silent and should be deleted rather than kept '
          'as a second spelling of the same value.',
    );
  }

  for (final (String mode, ThemeData Function() build)
      in <(String, ThemeData Function())>[
        ('light', buildLightTheme),
        ('dark', buildDarkTheme),
      ]) {
    group('$mode component themes resolve the app scale', () {
      final ThemeData theme = build();
      final TextTheme texts = theme.textTheme;

      test('the pill label is label-lg, declared one weight lighter', () {
        // 500 is Material's chip weight and `--weight-medium` in the kit. The
        // rung stays 600 for the button it was raised for; only the chip parts
        // from it, and `app_chip_theme.dart` holds the measurement that says why.
        expectRungReweighted(
          'chipTheme.labelStyle',
          theme.chipTheme.labelStyle,
          texts.labelLarge,
          FontWeight.w500,
        );
      });

      test('every button label is label-lg at the button weight', () {
        // **The rung is 600 and a button is 700** (M100.30). Tokyo puts
        // `fontWeight: 'bold'` on `MuiButton.root`, which every variant shares,
        // and that one declaration is most of why its actions read as
        // pressable rather than as coloured labels. It is a second emphatic
        // weight in an app that had one — 600 emphasises a word inside running
        // text, and a button is not running text.
        //
        // All four families, because the whole value of a shared style is that
        // none of them can drift: `buildSharedButtonStyle` carries it for
        // filled and outlined, `buildTextButtonTheme` restates it, and the
        // the destructive variant resolves through `buildFilledStyle`.
        // A family set one weight apart from its siblings is the exact drift
        // this is here to catch.
        for (final (String slot, WidgetStateProperty<TextStyle?>? style)
            in <(String, WidgetStateProperty<TextStyle?>?)>[
              ('filledButtonTheme', theme.filledButtonTheme.style?.textStyle),
              (
                'outlinedButtonTheme',
                theme.outlinedButtonTheme.style?.textStyle,
              ),
              ('textButtonTheme', theme.textButtonTheme.style?.textStyle),
            ]) {
          expect(style, isNotNull, reason: '$slot declares no label style');
          expectRungReweighted(
            '$slot.textStyle',
            style!.resolve(const <WidgetState>{}),
            texts.labelLarge,
            buttonLabelWeight,
          );
        }
      });

      test('the navigation label is label-md, and selection re-weights it', () {
        // The bar resolves per state, so both faces have to be asked for.
        // Unselected is the rung untouched; selected is the rung at 600 — and
        // the axis assertion inside the helper is the whole point, because
        // this slot shipped a `copyWith(fontWeight:)` that reported 600 and
        // painted 500 (theme-composition review, 2026-08).
        final WidgetStateProperty<TextStyle?>? label =
            theme.navigationBarTheme.labelTextStyle;
        expect(label, isNotNull, reason: 'the bar declares no label style');

        expectSameRung(
          'navigationBarTheme.labelTextStyle (unselected)',
          label!.resolve(const <WidgetState>{}),
          texts.labelMedium,
        );
        expectRungReweighted(
          'navigationBarTheme.labelTextStyle (selected)',
          label.resolve(const <WidgetState>{WidgetState.selected}),
          texts.labelMedium,
          FontWeight.w600,
        );
      });

      test('an input hint is body-md, leading included', () {
        expectSameRung(
          'inputDecorationTheme.hintStyle',
          theme.inputDecorationTheme.hintStyle,
          texts.bodyMedium,
        );
        // The leading is the half of this a family check would miss: Material's
        // body-md is 20/14, the design's is 1.45.
        expect(theme.inputDecorationTheme.hintStyle?.height, 1.45);
      });

      test('a tooltip is label-md', () {
        expectSameRung(
          'tooltipTheme.textStyle',
          theme.tooltipTheme.textStyle,
          texts.labelMedium,
        );
      });

      test('a dialog title is title-md and its body is body-md', () {
        expectSameRung(
          'dialogTheme.titleTextStyle',
          theme.dialogTheme.titleTextStyle,
          texts.titleMedium,
        );
        expect(
          theme.dialogTheme.titleTextStyle?.fontWeight,
          FontWeight.w600,
          reason: 'the dialog title is back on Material 3 title-md',
        );
        expectSameRung(
          'dialogTheme.contentTextStyle',
          theme.dialogTheme.contentTextStyle,
          texts.bodyMedium,
        );
      });

      test('a snackbar is body-md', () {
        expectSameRung(
          'snackBarTheme.contentTextStyle',
          theme.snackBarTheme.contentTextStyle,
          texts.bodyMedium,
        );
      });
    });
  }

  test('no component theme is built from the unstyled scale', () {
    // The behavioural tests above cover the six slots that exist today. This one
    // covers the seventh, written next year: `base.textTheme` is Material's
    // scale, and the only correct thing to do with it is hand it to
    // `buildTextTheme`. Anywhere else it is the bug this file was opened for.
    //
    // Source-level on purpose. A component theme added without a text style
    // inherits correctly and needs no test; one added *with* `base.textTheme`
    // needs to fail before anyone goes looking for why a weight is off by 100.
    final source = File(
      'lib/core/theme/app_theme.dart',
    ).readAsStringSync().replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');

    final uses = RegExp(r'\bbase\.textTheme\b').allMatches(source).length;

    expect(
      uses,
      1,
      reason:
          'base.textTheme is Material 3 scale, not the app scale. It belongs in '
          'exactly one place — the AppTypography.buildTextTheme(...) call whose '
          'result every other slot then reads.',
    );
    expect(
      source,
      contains('AppTypography.buildTextTheme(base.textTheme)'),
      reason: 'the one permitted use is no longer the buildTextTheme call',
    );
  });
}
