import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

/// `MxSearchField` — the v3 filled control under an app bar.
void main() {
  final light = buildLightTheme();

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
              semanticLabel: 'Search your library',
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

      expect(decorationOf(tester).color, light.colorScheme.surfaceContainer);
      // v3: the boundary is `border-ghost`, not `scheme.outline` — the same
      // low-contrast trade-off M100.101 already made for `MxTextField`.
      expect(
        decorationOf(tester).border!.top.color,
        AppDecorations.hairlineEdge(light.colorScheme).color,
      );
      expect(decorationOf(tester).border!.top.width, AppStroke.hairline);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(
        decorationOf(tester).color,
        light.colorScheme.surfaceContainerLowest,
        reason: 'a field being typed into stops being a well in the page',
      );
      expect(decorationOf(tester).border!.top.color, light.colorScheme.primary);
      expect(decorationOf(tester).border!.top.width, AppStroke.hairline);
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
        isNot(light.colorScheme.surfaceContainerLowest),
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

      expect(
        paintedDecorationOf(tester).color,
        light.colorScheme.surfaceContainerLowest,
      );
      expect(
        paintedDecorationOf(tester).border!.top.color,
        light.colorScheme.primary,
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
    testWidgets('the glyph and the text share a centre line', (tester) async {
      // OLD assertion: bottoms within a pixel — held by a `-0.1` vertical
      // nudge on a field that filled a fixed 48 box. NEW contract (M100.36,
      // and unchanged by the v3 geometry pass): the field is its own line
      // box, centred in the row like the glyph, so the relationship a centred
      // row actually has is the one asserted — not the "hint sits lower"
      // defect the old test was written for, which was a whole-box
      // misalignment. The glyph is 20 now (v3's `icon sm`), the same step as
      // the line box, so the two also land bottom-flush.
      await pump(tester);
      await tester.pumpAndSettle();

      final icon = tester.getRect(find.byIcon(Icons.search));
      final text = tester.getRect(find.byType(EditableText));

      expect(
        (text.center.dy - icon.center.dy).abs(),
        lessThan(1),
        reason: 'the two are on one line, within a pixel',
      );
    });

    testWidgets('52 is a floor: the pill grows with the text and clips '
        'nothing', (tester) async {
      // #433 F2: `SizedBox(height: 48)` + `expands: true` turned a documented
      // floor into a ceiling, and from 2.5× the placeholder was clipped to
      // the box — silently, because clipping is not an overflow. The floor
      // itself moved to 52 for the v3 SearchField spec's own input height;
      // the floor-not-ceiling mechanism this test guards did not.
      for (final width in <double>[320, 360, 393]) {
        for (final scale in <double>[1.0, 1.3, 2.0, 2.5, 3.0]) {
          tester.view.physicalSize = Size(width, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              theme: light,
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: Scaffold(
                    body: MxSearchField(
                      value: 'nouns',
                      onChanged: (_) {},
                      hintText: 'Search your whole library',
                      semanticLabel: 'Search your library',
                      resultCount: 7,
                      clearSemanticLabel: 'Clear search',
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final pill = tester.getRect(find.byType(MxSearchField));
          final text = tester.getRect(find.byType(EditableText));
          final why = '$width × $scale';
          expect(tester.takeException(), isNull, reason: why);
          expect(pill.height, greaterThanOrEqualTo(52), reason: why);
          expect(text.top, greaterThanOrEqualTo(pill.top), reason: why);
          expect(text.bottom, lessThanOrEqualTo(pill.bottom), reason: why);
          if (scale == 1.0) {
            // 53, not 52: the same text-engine-rounding pixel the old 48
            // floor carried (49, not 48) — `_fieldInset` scales with the
            // floor, so the inset grew with it and the content still lands
            // one pixel past its own floor. Still the floor plus a pixel, not
            // a floor violation — see `greaterThanOrEqualTo(52)` above.
            expect(pill.height, 53.0, reason: why);
          }
          if (scale >= 2.5) {
            expect(pill.height, greaterThan(52), reason: '$why: still pinned');
          }
        }
      }
    });
  });

  group('semantics', () {
    testWidgets('the name survives typing, and the query is the value', (
      tester,
    ) async {
      // #433 F1: named by its hint, the field was unnamed for exactly as long
      // as it held a query — `InputDecorator` wraps the hint in an `Opacity`
      // at zero, and `RenderOpacity` drops the child from the tree.
      final handle = tester.ensureSemantics();

      await pump(tester);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Search your library'), findsOneWidget);

      await pump(tester, value: 'nouns');
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Search your library'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(EditableText)).value,
        'nouns',
        reason: 'the query is not the field-s value',
      );
      expect(
        tester.getSemantics(find.byType(EditableText)),
        matchesSemantics(
          isTextField: true,
          value: 'nouns',
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      // Painted once, announced never: the hint is excluded so the name is
      // not read twice on an empty field.
      expect(find.bySemanticsLabel('Search your whole library'), findsNothing);
      handle.dispose();
    });
  });
}
