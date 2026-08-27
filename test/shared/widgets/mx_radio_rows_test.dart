import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
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
}
