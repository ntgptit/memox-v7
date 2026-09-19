import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

/// `MxFilterChip`'s paint (fill, edge, count dimming) and its behaviour under
/// hostile constraints (a tight scroll band, large text). Split from
/// `mx_filter_chip_test.dart` for the guard's file-size limit.
void main() {
  Future<void> pump(WidgetTester tester, Widget chip) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: Center(child: chip)),
      ),
    );
  }

  Finder paintedMaterial() => find
      .descendant(
        of: find.byType(MxFilterChip),
        matching: find.byType(Material),
      )
      .first;

  group('paint', () {
    final ThemeData theme = buildLightTheme();

    Material pill(WidgetTester tester) =>
        tester.widget<Material>(paintedMaterial());

    testWidgets('a selected chip is filled with primary and has no edge', (
      tester,
    ) async {
      await pump(
        tester,
        MxFilterChip(label: 'Cards', isSelected: true, onPressed: () {}),
      );

      expect(pill(tester).color, theme.colorScheme.primary);
      expect(
        (pill(tester).shape! as RoundedRectangleBorder).side,
        BorderSide.none,
      );
    });

    testWidgets('an unselected chip wears surfaceContainerLowest and the ghost '
        'edge', (tester) async {
      await pump(
        tester,
        MxFilterChip(label: 'Cards', isSelected: false, onPressed: () {}),
      );

      expect(pill(tester).color, theme.colorScheme.surfaceContainerLowest);
      expect(
        (pill(tester).shape! as RoundedRectangleBorder).side.color,
        theme.extension<AppSemanticColors>()!.borderGhost,
      );
    });

    for (final (bool isSelected, double opacity) in <(bool, double)>[
      (false, 0.6),
      (true, 0.75),
    ]) {
      testWidgets('the count is dimmed to $opacity when '
          '${isSelected ? 'selected' : 'unselected'}', (tester) async {
        await pump(
          tester,
          MxFilterChip(
            label: 'Cards',
            count: 4,
            isSelected: isSelected,
            onPressed: () {},
          ),
        );

        final Opacity dim = tester.widget<Opacity>(
          find
              .ancestor(of: find.text('4'), matching: find.byType(Opacity))
              .first,
        );
        expect(dim.opacity, opacity);
      });
    }
  });

  group('constraints', () {
    testWidgets('a tight 48dp horizontal band still paints a 28dp pill', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  MxFilterChip(
                    label: 'Cards',
                    isSelected: true,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(paintedMaterial()).height, AppSizing.controlChip);
      expect(
        tester.getSize(find.byType(MxFilterChip)).height,
        AppSizing.touchTarget,
      );
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(MxFilterChip)).rect.height,
        AppSizing.touchTarget,
      );
      handle.dispose();
    });

    for (final double scale in <double>[2.0, 3.0]) {
      testWidgets('at ${scale}x text the label stays centred in a 28dp pill', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildLightTheme(),
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Center(
                  child: MxFilterChip(
                    label: 'Cards',
                    isSelected: false,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        final Rect pillRect = tester.getRect(paintedMaterial());
        expect(pillRect.height, AppSizing.controlChip);
        final Rect textRect = tester.getRect(find.text('Cards'));
        // Not clamped to the pill (a clamped box is trivially centred while
        // its glyphs are painted top-aligned), and centred on it.
        expect(textRect.height, greaterThan(pillRect.height));
        expect(textRect.center.dy, closeTo(pillRect.center.dy, 0.5));
      });
    }
  });
}
