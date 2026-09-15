import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

/// The loading family — three shapes, one accessible name (A20.1 P1-02).
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  for (final (String name, Widget widget) in <(String, Widget)>[
    ('fullArea', const MxLoadingState(semanticsLabel: 'Loading cards')),
    (
      'inColumn',
      const MxLoadingState.inColumn(semanticsLabel: 'Loading cards'),
    ),
    ('inline', const MxLoadingState.inline(semanticsLabel: 'Loading cards')),
  ]) {
    testWidgets('$name carries its name to the indicator', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, widget);

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.semanticsLabel, 'Loading cards');
      expect(find.bySemanticsLabel('Loading cards'), findsOneWidget);
      // The theme supplies the colour; the widget never does.
      expect(indicator.color, isNull, reason: '$name overrides the theme');
      handle.dispose();
    });
  }

  testWidgets('inline is the 16 dp mark at the indicator stroke', (
    tester,
  ) async {
    await pump(tester, const MxLoadingState.inline(semanticsLabel: 'More'));

    final size = tester.getSize(find.byType(CircularProgressIndicator));
    expect(size, const Size.square(AppIconSize.sm));
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .strokeWidth,
      AppStroke.indicator,
    );
  });

  testWidgets('fullArea centres with a gutter; inColumn adds none', (
    tester,
  ) async {
    await pump(tester, const MxLoadingState(semanticsLabel: 'x'));
    expect(find.byType(Padding), findsWidgets);
    final full = tester.getSize(find.byType(MxLoadingState));

    await pump(tester, const MxLoadingState.inColumn(semanticsLabel: 'x'));
    final column = tester.getSize(find.byType(MxLoadingState));
    expect(column.height, lessThan(full.height));
  });
}
