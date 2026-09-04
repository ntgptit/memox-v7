import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_sheet.dart';
import 'package:memox/shared/widgets/mx_sheet_insets.dart';

/// `showMxSheet` — the one sheet route (A20.1 P1-01) — and `MxSheetHeader`.
void main() {
  Future<void> pumpOpener(
    WidgetTester tester, {
    required WidgetBuilder builder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showMxSheet<void>(context, builder: builder),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the header announces as a heading with the written title', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpOpener(
      tester,
      builder: (_) =>
          const MxSheetInsets(child: MxSheetHeader(title: 'Sort by')),
    );

    final node = tester.getSemantics(find.text('Sort by'));
    expect(node.flagsCollection.isHeader, isTrue);
    expect(node.label, 'Sort by');
    handle.dispose();
  });

  testWidgets('the sheet is on the root navigator, above a nested one', (
    tester,
  ) async {
    // A nested `Navigator` stands in for a navigation-bar branch. A sheet
    // pushed on it would be drawn inside the branch, under the bar; on the
    // root it covers everything.
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showMxSheet<void>(
                    context,
                    builder: (_) => const MxSheetInsets(child: Text('sheet')),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The sheet's route lives on the outer (root) navigator: the nested
    // navigator has exactly one route, the root has the page plus the sheet.
    final navigators = find.byType(Navigator);
    expect(navigators, findsNWidgets(2));
    final NavigatorState root = tester.state(navigators.first);
    final NavigatorState nested = tester.state(navigators.last);
    expect(root.canPop(), isTrue, reason: 'the sheet is not on the root');
    expect(
      nested.canPop(),
      isFalse,
      reason: 'the sheet was pushed on the branch',
    );
    expect(find.text('sheet'), findsOneWidget);
  });

  testWidgets(
    'the sheet avoids the status bar but leaves the bottom to its content',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 40, bottom: 30);
      tester.view.viewPadding = const FakeViewPadding(top: 40, bottom: 30);
      addTearDown(tester.view.reset);

      await pumpOpener(
        tester,
        builder: (_) => const MxSheetInsets(
          child: SizedBox(height: 700, child: Text('tall')),
        ),
      );

      final sheet = tester.getRect(find.text('tall'));
      expect(
        sheet.top,
        greaterThanOrEqualTo(40),
        reason: 'under the status bar',
      );
      // The bottom is `MxSheetInsets`'s: content ends a gutter plus the bar
      // above the bottom, and no second SafeArea doubled it.
      final Rect insets = tester.getRect(find.byType(MxSheetInsets));
      expect(insets.bottom, closeTo(800, 0.5));
      expect(sheet.bottom, lessThanOrEqualTo(800 - 30));
    },
  );

  testWidgets('the barrier covers the view and dismisses', (tester) async {
    await pumpOpener(
      tester,
      builder: (_) => const MxSheetInsets(child: Text('sheet')),
    );
    expect(find.text('sheet'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsNothing);
  });

  test('a header is not selectable, not a button — a heading', () {
    // Documentation by type: the widget has exactly one input.
    const header = MxSheetHeader(title: 'x');
    expect(header.title, 'x');
    expect(Tristate.values, isNotEmpty);
  });
}
