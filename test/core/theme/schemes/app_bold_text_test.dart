import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/extensions/theme_context_extension.dart';
import 'package:memox/core/theme/typography/app_text_styles.dart';

/// A20.1 P1-11 — the OS Bold text setting moves the resolved `wght` axis,
/// not just `fontWeight`.
void main() {
  double wghtOf(WidgetTester tester, String text) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
    final variations = paragraph.text.style!.fontVariations!;
    return variations.singleWhere((v) => v.axis == 'wght').value;
  }

  Future<void> pump(WidgetTester tester, {required bool boldText}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(boldText: boldText),
          child: BoldTextWidget(child: child!),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: <Widget>[
                Text('body', style: context.texts.bodyMedium),
                Text('title', style: context.texts.titleMedium),
                Text('label', style: context.texts.labelSmall),
                Text('hero', style: context.textStyles.heroNumeral),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('without the setting, each rung keeps its own weight', (
    tester,
  ) async {
    await pump(tester, boldText: false);
    // `body` used to be pinned at 400. What this test needs from it is that it
    // is NOT already bold — the same thing `label` asserts — so the rung's
    // resting weight is free to be retuned without touching this file.
    // `hero` joined them when GC-4 dropped its always-bold exception (R6): it
    // is the stat rung's own 600 now, not a feature-declared 700.
    for (final text in <String>['body', 'label', 'hero']) {
      expect(wghtOf(tester, text), lessThan(700), reason: text);
    }
  });

  testWidgets('with the setting, every rung resolves the wght axis to 700', (
    tester,
  ) async {
    await pump(tester, boldText: true);
    for (final text in <String>['body', 'title', 'label', 'hero']) {
      expect(wghtOf(tester, text), 700, reason: '$text did not embolden');
    }
    // The metrics (the cap-trim) stay untouched — bold text changes a rung's
    // weight, never its geometry.
    final hero = tester.renderObject<RenderParagraph>(find.text('hero'));
    expect(
      hero.text.style!.height,
      buildLightTheme().extension<AppTextStyles>()!.heroNumeral.height,
    );
  });
}
