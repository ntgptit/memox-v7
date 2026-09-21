import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_mastery_donut.dart';

void main() {
  testWidgets('renders a fixed 56dp semantic mastery readout', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: MxMasteryDonut(progress: .67)),
      ),
    );

    expect(tester.getSize(find.byType(MxMasteryDonut)), const Size(56, 56));
    expect(find.text('67%'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(MxMasteryDonut)).label,
      '67% mastery',
    );
  });

  test('rejects a percentage outside its closed range', () {
    expect(() => MxMasteryDonut(progress: -0.1), throwsArgumentError);
    expect(() => MxMasteryDonut(progress: 1.1), throwsArgumentError);
  });
}
