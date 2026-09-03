import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_radio_rows.dart';

/// The two fixes the group owns — the transparent Material inside a decorated
/// card, and the per-tile lock — plus the pick itself.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('carries its own transparent Material inside a painted card', (
    tester,
  ) async {
    // The setting the settings rows discovered: without this the nearest
    // Material sits behind the card's opaque fill and every ripple is drawn
    // and then covered.
    await tester.pumpWidget(
      host(
        DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF888888)),
          child: MxRadioRows<int>(
            values: const <int>[0, 1],
            selected: 0,
            onChanged: (_) {},
            labelOf: (value) => 'choice $value',
          ),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(MxRadioRows<int>),
        matching: find.byType(Material),
      ),
    );
    expect(material.type, MaterialType.transparency);
  });

  testWidgets('tapping a row picks its value', (tester) async {
    int? picked;
    await tester.pumpWidget(
      host(
        MxRadioRows<int>(
          values: const <int>[0, 1],
          selected: 0,
          onChanged: (value) => picked = value,
          labelOf: (value) => 'choice $value',
        ),
      ),
    );

    await tester.tap(find.text('choice 1'));
    expect(picked, 1);
  });

  testWidgets('a locked group greys its rows and changes nothing', (
    tester,
  ) async {
    int? picked;
    await tester.pumpWidget(
      host(
        MxRadioRows<int>(
          values: const <int>[0, 1],
          selected: 0,
          isEnabled: false,
          onChanged: (value) => picked = value,
          labelOf: (value) => 'choice $value',
        ),
      ),
    );

    for (final tile in tester.widgetList<RadioListTile<int>>(
      find.byType(RadioListTile<int>),
    )) {
      expect(tile.enabled, isFalse);
    }
    await tester.tap(find.text('choice 1'), warnIfMissed: false);
    expect(picked, isNull);
  });

  testWidgets('a list divides with the theme-s hairline and pads its own '
      'gutter; a block does neither', (tester) async {
    // #431 P2-4 / P2-6 / P2-17: the divider was `borderDivider` — a second
    // hairline that in light was the page colour — and the gutter was a public
    // `EdgeInsets` the settings screen filled with a literal that did not
    // follow the compact scale. Both are the shape's now (M100.36 10H, 10I).
    for (final shape in MxRadioRowsShape.values) {
      await tester.pumpWidget(
        host(
          MxRadioRows<int>(
            values: const <int>[0, 1],
            selected: 0,
            onChanged: (_) {},
            labelOf: (value) => 'choice $value',
            shape: shape,
          ),
        ),
      );
      final theme = buildLightTheme();
      final dividers = find.byType(Divider);
      final tiles = tester.widgetList<RadioListTile<int>>(
        find.byType(RadioListTile<int>),
      );

      if (shape == MxRadioRowsShape.block) {
        expect(dividers, findsNothing, reason: 'a block drew a divider');
        for (final tile in tiles) {
          expect(tile.contentPadding, EdgeInsets.zero, reason: 'block gutter');
        }
        continue;
      }

      expect(dividers, findsOneWidget, reason: 'a list of two has one line');
      final divider = tester.widget<Divider>(dividers);
      expect(divider.color, isNull, reason: 'the line is not the theme-s');
      expect(divider.height, isNull);
      expect(theme.dividerTheme.color, theme.colorScheme.outlineVariant);
      for (final tile in tiles) {
        expect(
          tile.contentPadding,
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          reason: 'a list row supplies the screen gutter',
        );
      }
    }
  });
}
