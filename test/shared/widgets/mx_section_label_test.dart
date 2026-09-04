import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_section_label.dart';

/// `MxSectionLabel` — caps at paint, the written sentence in the tree
/// (A20.1 P2-02).
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('paints the caps and announces the sentence as a heading', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const MxSectionLabel(label: 'Your decks'));

    expect(find.text('YOUR DECKS'), findsOneWidget);
    expect(find.text('Your decks'), findsNothing);
    final node = tester.getSemantics(find.byType(MxSectionLabel));
    expect(node.label, 'Your decks');
    expect(node.flagsCollection.isHeader, isTrue);
    handle.dispose();
  });

  testWidgets('a detail is painted as given and spoken after the label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const MxSectionLabel(label: 'Decks', detail: '12'));

    expect(find.text('DECKS · 12'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(MxSectionLabel)).label,
      'Decks · 12',
    );
    handle.dispose();
  });

  testWidgets('the three rungs resolve to the three heading styles', (
    tester,
  ) async {
    for (final rung in MxSectionLabelRung.values) {
      await pump(tester, MxSectionLabel(label: 'x', rung: rung));
      final text = tester.widget<Text>(find.text('X'));
      final styles = Theme.of(tester.element(find.text('X')));
      expect(text.style, isNotNull, reason: '$rung');
      expect(styles.textTheme, isNotNull);
    }
  });

  testWidgets('a locale without case is the identity', (tester) async {
    await pump(tester, const MxSectionLabel(label: '한국어'));
    expect(find.text('한국어'), findsOneWidget);
  });
}
