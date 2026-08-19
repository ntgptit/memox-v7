import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'render_classification.dart';

/// Fault injection for the one entry in [renderPaintsNothing] that is a
/// *conditional* claim rather than a flat one.
///
/// Every other type in that list is vouched for unconditionally, so a wrong
/// entry would be wrong on every screen and any audit would notice. `RenderTable`
/// is different: it paints nothing for a plain table and paints two different
/// things — a border, and per-row decorations — for a decorated one, and
/// `RenderTable.paint` runs those two branches independently of each other.
///
/// A guard that only asked about `border` therefore returned `true` for a table
/// whose `TableRow` carried a `BoxDecoration`, and that row colour was read by
/// nobody: `screen_auditor.dart` returns before it tells the sink anything, so
/// the node did not even appear in the skip list that makes the audit's coverage
/// self-declaring. The only way to prove the guard guards is to hand it the
/// table it is supposed to refuse.
void main() {
  Future<RenderTable> pumpTable(WidgetTester tester, Table table) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: table)));

    return tester.renderObject<RenderTable>(find.byType(Table));
  }

  const TableRow plainRow = TableRow(
    children: <Widget>[SizedBox(width: 40, height: 8)],
  );

  testWidgets('a plain table paints nothing', (tester) async {
    final RenderTable node = await pumpTable(
      tester,
      Table(children: const <TableRow>[plainRow]),
    );

    expect(node.border, isNull);
    expect(node.rowDecorations, everyElement(isNull));
    expect(renderPaintsNothing(node), isTrue);
  });

  testWidgets('a table with a border is reported', (tester) async {
    final RenderTable node = await pumpTable(
      tester,
      Table(
        border: TableBorder.all(color: const Color(0xFF112233)),
        children: const <TableRow>[plainRow],
      ),
    );

    expect(renderPaintsNothing(node), isFalse);
  });

  testWidgets('a table with a decorated row is reported', (tester) async {
    final RenderTable node = await pumpTable(
      tester,
      Table(
        children: const <TableRow>[
          TableRow(
            decoration: BoxDecoration(color: Color(0xFF445566)),
            children: <Widget>[SizedBox(width: 40, height: 8)],
          ),
        ],
      ),
    );

    // The regression this file exists for: `border` is null here, so a guard
    // written against `border` alone would have called this harmless.
    expect(node.border, isNull);
    expect(renderPaintsNothing(node), isFalse);
  });
}
