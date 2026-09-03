import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_switch_row.dart';

/// The axis the widget owns is a semantics decision, so that is what the
/// tests pin: the announced variant speaks its value in words from the switch
/// alone, and the tile variant makes the whole row the target.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('announced: the switch alone carries label and value in words', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        MxSwitchRow(
          label: 'Reminders',
          announcedValue: 'On',
          isOn: true,
          onChanged: (_) {},
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(Switch));
    expect(node.label, contains('Reminders'));
    expect(node.value, 'On');
    handle.dispose();
  });

  testWidgets('announced: the label is the tap target for nothing', (
    tester,
  ) async {
    var changes = 0;
    await tester.pumpWidget(
      host(
        MxSwitchRow(
          label: 'Reminders',
          announcedValue: 'Off',
          isOn: false,
          onChanged: (_) => changes += 1,
        ),
      ),
    );

    await tester.tap(find.text('Reminders'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(changes, 0);

    await tester.tap(find.byType(Switch));
    expect(changes, 1);
  });

  testWidgets('tile: the whole row toggles', (tester) async {
    var changes = 0;
    await tester.pumpWidget(
      host(
        MxSwitchRow(
          label: 'Has header row',
          isOn: false,
          onChanged: (_) => changes += 1,
        ),
      ),
    );

    await tester.tap(find.text('Has header row'));
    expect(changes, 1);
  });

  testWidgets('null onChanged locks both variants', (tester) async {
    await tester.pumpWidget(
      host(
        const Column(
          children: <Widget>[
            MxSwitchRow(label: 'tile', isOn: true, onChanged: null),
            MxSwitchRow(
              label: 'announced',
              announcedValue: 'On',
              isOn: true,
              onChanged: null,
            ),
          ],
        ),
      ),
    );

    for (final switchWidget in tester.widgetList<Switch>(find.byType(Switch))) {
      expect(switchWidget.onChanged, isNull);
    }
  });

  testWidgets('both variants set the label at one rung', (tester) async {
    // #431 P2-12: the tile branch was body-md and the announced one body-lg —
    // one widget, two type scales, decided by a semantics flag.
    await tester.pumpWidget(
      host(
        Column(
          children: <Widget>[
            MxSwitchRow(label: 'tile', isOn: true, onChanged: (_) {}),
            MxSwitchRow(
              label: 'announced',
              announcedValue: 'On',
              isOn: true,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
    final rung = buildLightTheme().textTheme.bodyLarge!.fontSize;
    for (final label in <String>['tile', 'announced']) {
      final text = tester.renderObject<RenderParagraph>(find.text(label));
      expect(text.text.style?.fontSize, rung, reason: label);
    }
  });
}
