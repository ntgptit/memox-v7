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
    bool disableAnimations = false,
    ValueChanged<String>? onChanged,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: light,
      home: Builder(
        // `copyWith` on the real data, never a fresh `MediaQueryData`:
        // constructing one zeroes `size` and `padding`, so the widget is told
        // the screen is 0x0 while the view says otherwise.
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: Scaffold(
            body: MxSearchField(
              value: value,
              onChanged: onChanged ?? (_) {},
              hintText: 'Search your whole library',
              resultCount: resultCount,
              clearSemanticLabel: 'Clear search',
            ),
          ),
        ),
      ),
    ),
  );

  BoxDecoration decorationOf(WidgetTester tester) =>
      tester
              .widget<AnimatedContainer>(find.byType(AnimatedContainer))
              .decoration!
          as BoxDecoration;

  /// The decoration the pill is *painting*, as opposed to the one it is heading
  /// for. `AnimatedContainer`'s own `decoration` is the target and changes in
  /// the frame the state does, so reading it would call every transition
  /// instant — including the one this test is trying to prove is not.
  BoxDecoration paintedDecorationOf(WidgetTester tester) =>
      tester
              .widget<DecoratedBox>(
                find
                    .descendant(
                      of: find.byType(AnimatedContainer),
                      matching: find.byType(DecoratedBox),
                    )
                    .first,
              )
              .decoration
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

  group('reduced motion', () {
    testWidgets('the focus crossfade runs when animation is allowed', (
      tester,
    ) async {
      // The control case, and it is what makes the next test mean anything: if
      // the pill were instant either way, a broken policy would still pass.
      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(
        paintedDecorationOf(tester).color,
        isNot(light.colorScheme.surface),
        reason: 'the pill arrived before the transition had run',
      );
    });

    testWidgets('the focus state arrives in one frame when it is not', (
      tester,
    ) async {
      await pump(tester, disableAnimations: true);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(paintedDecorationOf(tester).color, light.colorScheme.surface);
      expect(
        paintedDecorationOf(tester).border!.top.color,
        semantic.focusRing,
        reason: 'the border did not reach its focused hue',
      );
    });

    testWidgets('the size, the semantics and the callback are untouched', (
      tester,
    ) async {
      // Reduced motion removes movement, never behaviour. A policy that also
      // dropped the clear button's callback would be answering a different
      // request from the one the platform flag makes.
      final typed = <String>[];
      await pump(
        tester,
        value: 'nouns',
        disableAnimations: true,
        onChanged: typed.add,
      );
      await tester.pumpAndSettle();
      final atRest = tester.getSize(find.byType(MxSearchField));

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(tester.getSize(find.byType(MxSearchField)), atRest);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();

      expect(typed, <String>['']);
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
