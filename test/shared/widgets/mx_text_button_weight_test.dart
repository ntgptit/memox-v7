import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/components/actions/app_button_themes.dart';
import 'package:memox/shared/widgets/mx_text_button.dart';

/// `MxTextButton` paints the button weight at both rungs — read off the
/// `RenderParagraph`, not off `ThemeData`.
///
/// `component_theme_typography_test.dart` pins the three theme slots at
/// `buttonLabelWeight` and cannot see a widget-level override; that is exactly
/// how the compact link survived M100.30 at `label-md`'s own 500 while every
/// other button in the app painted 700 (#432 P2-1). A flat
/// `WidgetStatePropertyAll(labelMedium)` shadowed the theme's resolver for
/// every state — weight, `wght` axis and the focus underline alike.
void main() {
  Future<RenderParagraph> paragraphOf(
    WidgetTester tester, {
    required bool isCompact,
    bool isDark = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: Scaffold(
          body: Center(
            child: MxTextButton(
              label: 'Recent',
              isCompact: isCompact,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return tester.renderObject<RenderParagraph>(find.text('Recent'));
  }

  for (final mode in <(String, bool)>[('light', false), ('dark', true)]) {
    final label = mode.$1;
    final isDark = mode.$2;
    final texts = (isDark ? buildDarkTheme() : buildLightTheme()).textTheme;

    testWidgets('$label · standard paints label-lg at the button weight, '
        'through the wght axis', (tester) async {
      final text = await paragraphOf(tester, isCompact: false, isDark: isDark);
      final style = text.text.style!;

      expect(style.fontSize, texts.labelLarge!.fontSize, reason: label);
      expect(style.fontWeight, buttonLabelWeight, reason: label);
      expect(
        style.fontVariations,
        contains(FontVariation('wght', buttonLabelWeight.value.toDouble())),
        reason: '$label: the axis did not move — 700 reported, 600 painted',
      );
    });

    testWidgets('$label · compact steps the size down and keeps the weight', (
      tester,
    ) async {
      final text = await paragraphOf(tester, isCompact: true, isDark: isDark);
      final style = text.text.style!;
      final rung = texts.labelMedium!;

      // Size, leading and tracking are the rung's: that is what "compact"
      // changes.
      expect(style.fontSize, rung.fontSize, reason: label);
      expect(style.height, rung.height, reason: label);
      expect(style.letterSpacing, rung.letterSpacing, reason: label);
      // Weight is the button's, and it has to reach the variable font's axis
      // or it is a number the renderer never reads.
      expect(style.fontWeight, buttonLabelWeight, reason: label);
      expect(
        style.fontVariations,
        contains(FontVariation('wght', buttonLabelWeight.value.toDouble())),
        reason: '$label: compact painted the rung-s own weight',
      );
    });
  }
}
