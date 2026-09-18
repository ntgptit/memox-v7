import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_section_label.dart';

/// `MxSection` — an optional overline over a card of rows, hairline-divided,
/// with an optional note underneath.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  List<Widget> rowsOf(int count) =>
      List<Widget>.generate(count, (i) => ListTile(title: Text('Row $i')));

  testWidgets('a title renders as an MxSectionLabel with that title', (
    tester,
  ) async {
    await pump(tester, MxSection(title: 'Notifications', rows: rowsOf(1)));

    final label = tester.widget<MxSectionLabel>(find.byType(MxSectionLabel));
    expect(label.label, 'Notifications');
  });

  testWidgets('an untitled section has no MxSectionLabel in its tree', (
    tester,
  ) async {
    await pump(tester, MxSection(rows: rowsOf(1)));

    expect(find.byType(MxSectionLabel), findsNothing);
  });

  testWidgets('one row renders with no divider', (tester) async {
    await pump(tester, MxSection(rows: rowsOf(1)));

    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('three rows render with exactly two dividers between them', (
    tester,
  ) async {
    await pump(tester, MxSection(rows: rowsOf(3)));

    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('the row container is an MxCard with padding none', (
    tester,
  ) async {
    await pump(tester, MxSection(rows: rowsOf(2)));

    final card = tester.widget<MxCard>(find.byType(MxCard));
    expect(card.padding, MxCardPadding.none);
  });

  testWidgets('a note renders as text below the card', (tester) async {
    await pump(
      tester,
      MxSection(rows: rowsOf(1), note: 'Applies to this device only.'),
    );

    expect(find.text('Applies to this device only.'), findsOneWidget);
  });

  testWidgets('omitting the note renders no extra text', (tester) async {
    await pump(tester, MxSection(rows: rowsOf(1)));

    expect(find.text('Applies to this device only.'), findsNothing);
  });

  testWidgets('an empty rows list throws an assertion error', (tester) async {
    expect(() => MxSection(rows: const <Widget>[]), throwsAssertionError);
  });
}
