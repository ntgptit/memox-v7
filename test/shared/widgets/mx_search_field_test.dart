import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

/// `MxSearchField` — the filled pill under an app bar.
void main() {
  final light = buildLightTheme();
  final semantic = light.extension<AppSemanticColors>()!;

  Future<void> pump(
    WidgetTester tester, {
    String value = '',
    int? resultCount,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: light,
      home: Scaffold(
        body: MxSearchField(
          value: value,
          onChanged: (_) {},
          hintText: 'Search your whole library',
          resultCount: resultCount,
          clearSemanticLabel: 'Clear search',
        ),
      ),
    ),
  );

  BoxDecoration decorationOf(WidgetTester tester) =>
      tester
              .widget<AnimatedContainer>(find.byType(AnimatedContainer))
              .decoration!
          as BoxDecoration;

  group('focus', () {
    testWidgets('lifts the fill and colours the border', (tester) async {
      await pump(tester);
      await tester.pumpAndSettle();

      expect(decorationOf(tester).color, semantic.surfaceMuted);
      expect(decorationOf(tester).border!.top.color, semantic.surfaceMuted);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(
        decorationOf(tester).color,
        light.colorScheme.surface,
        reason: 'a field being typed into stops being a well in the page',
      );
      expect(decorationOf(tester).border!.top.color, semantic.focusRing);
    });

    testWidgets('the border is there at rest, so focus costs no layout', (
      tester,
    ) async {
      // The design carries a 1px *transparent* border for exactly this reason:
      // the same rule the form input follows, where focus shifts the border's
      // hue and never its width, so nothing laid out beside it is nudged.
      await pump(tester);
      await tester.pumpAndSettle();
      final atRest = tester.getSize(find.byType(MxSearchField));

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(MxSearchField)), atRest);
    });
  });

  group('the trailing controls', () {
    testWidgets('are absent until something has been typed', (tester) async {
      // An empty field with a clear button on it offers to undo nothing.
      await pump(tester, resultCount: 7);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.text('7'), findsNothing);
    });

    testWidgets('show the count and the clear button once it has', (
      tester,
    ) async {
      await pump(tester, value: 'nouns', resultCount: 7);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('the count stays out when the screen does not know it', (
      tester,
    ) async {
      await pump(tester, value: 'nouns');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('7'), findsNothing);
    });
  });

  group('layout', () {
    testWidgets('the glyph and the text share a bottom edge', (tester) async {
      // The bug this replaces: the field's vertical slack made the hint sit a
      // touch lower than the search icon, which reads as the two being on
      // different lines.
      await pump(tester);
      await tester.pumpAndSettle();

      final icon = tester.getRect(find.byIcon(Icons.search));
      final text = tester.getRect(find.byType(EditableText));

      expect(
        (text.bottom - icon.bottom).abs(),
        lessThan(1),
        reason: 'the two are on one line, within a pixel',
      );
    });
  });
}
