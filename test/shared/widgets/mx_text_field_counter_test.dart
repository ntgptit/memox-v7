import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The counter whispers only near the limit (mobile-ui-design forms rule):
/// invisible below 80% of maxLength, visible from 80%, and always keeping its
/// line so appearing never reflows what sits under the field.
void main() {
  Future<TextEditingController> pump(WidgetTester tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Column(
            children: <Widget>[
              MxTextField(
                controller: controller,
                label: 'Front',
                maxLength: 10,
              ),
              const Text('below-anchor'),
            ],
          ),
        ),
      ),
    );

    return controller;
  }

  testWidgets('hidden below 80% of the limit, visible from 80%', (
    tester,
  ) async {
    final controller = await pump(tester);

    // `maintainSize` keeps the hidden counter in the tree (that is the whole
    // point — no reflow), so presence is asserted at the interaction layer:
    // an invisible counter is not hit-testable, a visible one is.
    expect(find.text('0/10').hitTestable(), findsNothing);

    controller.text = 'abcdefg'; // 7 < 8
    await tester.pump();
    expect(find.text('7/10').hitTestable(), findsNothing);

    controller.text = 'abcdefgh'; // 8 == 80%
    await tester.pump();
    expect(find.text('8/10').hitTestable(), findsOneWidget);

    controller.text = 'abcdefghij';
    await tester.pump();
    expect(find.text('10/10').hitTestable(), findsOneWidget);
  });

  testWidgets('appearing does not move what sits under the field', (
    tester,
  ) async {
    final controller = await pump(tester);
    final before = tester.getTopLeft(find.text('below-anchor'));

    controller.text = 'abcdefghij';
    await tester.pump();
    final after = tester.getTopLeft(find.text('below-anchor'));

    expect(after, before, reason: 'the counter arriving reflowed the layout');
  });
}
