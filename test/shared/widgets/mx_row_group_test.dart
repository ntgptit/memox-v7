import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';
import 'package:memox/shared/widgets/mx_row_group.dart';

/// Handoff ListRow (C): a hairline between rows, none after the last; the
/// divider indents 56 when rows lead with a tile.
void main() {
  Future<void> pump(WidgetTester tester, MxRowDividerInset inset) =>
      tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: MxRowGroup(
              inset: inset,
              children: const <Widget>[
                MxListTile(title: 'One'),
                MxListTile(title: 'Two'),
                MxListTile(title: 'Three'),
              ],
            ),
          ),
        ),
      );

  testWidgets('n rows carry n - 1 dividers', (tester) async {
    await pump(tester, MxRowDividerInset.leading);
    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('the inset follows the leading column', (tester) async {
    await pump(tester, MxRowDividerInset.leading);
    expect(
      tester.widget<Divider>(find.byType(Divider).first).indent,
      AppSizing.listDividerIndent,
    );

    await pump(tester, MxRowDividerInset.none);
    expect(tester.widget<Divider>(find.byType(Divider).first).indent, 0);
  });

  testWidgets('a row is at least 48', (tester) async {
    await pump(tester, MxRowDividerInset.none);
    expect(
      tester.getSize(find.byType(ListTile).first).height,
      greaterThanOrEqualTo(AppSizing.rowMinHeight),
    );
    expect(AppSizing.rowMinHeight, AppSizing.touchTarget);
  });
}
