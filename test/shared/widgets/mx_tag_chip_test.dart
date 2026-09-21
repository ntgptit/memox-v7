import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: child),
    ),
  );

  testWidgets('uses the fixed default and dense heights', (tester) async {
    await pump(tester, const MxTagChip(label: 'German'));
    expect(tester.getSize(find.byType(MxTagChip)).height, 22);

    await pump(tester, const MxTagChip(label: 'German', dense: true));
    expect(tester.getSize(find.byType(MxTagChip)).height, 18);
  });

  testWidgets('caps a long tag at 140dp and ellipsizes it', (tester) async {
    await pump(
      tester,
      const MxTagChip(label: 'A very long tag name that cannot fit'),
    );

    expect(
      tester.getSize(find.byType(MxTagChip)).width,
      lessThanOrEqualTo(140),
    );
    expect(
      tester
          .widget<Text>(find.text('A very long tag name that cannot fit'))
          .overflow,
      TextOverflow.ellipsis,
    );
  });
}
