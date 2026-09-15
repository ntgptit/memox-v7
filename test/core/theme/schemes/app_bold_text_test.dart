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
    expect(wghtOf(tester, 'body'), 400);
    expect(wghtOf(tester, 'label'), lessThan(700));
    expect(wghtOf(tester, 'hero'), 700);
  });

  testWidgets('with the setting, every rung resolves the wght axis to 700', (
    tester,
  ) async {
    await pump(tester, boldText: true);
    for (final text in <String>['body', 'title', 'label']) {
      expect(wghtOf(tester, text), 700, reason: '$text did not embolden');
    }
    // Already bold: unchanged, and its metrics (the cap-trim) untouched.
    expect(wghtOf(tester, 'hero'), 700);
    final hero = tester.renderObject<RenderParagraph>(find.text('hero'));
    expect(
      hero.text.style!.height,
      buildLightTheme().extension<AppTextStyles>()!.heroNumeral.height,
    );
  });
}
