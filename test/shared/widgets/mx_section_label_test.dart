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

  testWidgets('standard is the handoff overline, list is the ls-label heading', (
    tester,
  ) async {
    // The handoff SectionHeader: the caption at 12/600, tracked 1.2 (M100.91).
    // After D1 the old `small` rung resolved to the same metrics, so two names
    // for one look were a distinction nobody could see; one rung remains.
    await pump(tester, const MxSectionLabel(label: 'x'));
    final overline = tester.widget<Text>(find.text('X')).style!;
    expect(overline.fontSize, 12);
    expect(overline.fontWeight, FontWeight.w600);
    expect(overline.letterSpacing, 1.2);

    await pump(
      tester,
      const MxSectionLabel(label: 'x', rung: MxSectionLabelRung.list),
    );
    final heading = tester.widget<Text>(find.text('X')).style!;
    expect(heading.letterSpacing, 0.72);
    expect(MxSectionLabelRung.values, hasLength(2));
  });

  testWidgets('a locale without case is the identity', (tester) async {
    await pump(tester, const MxSectionLabel(label: '한국어'));
    expect(find.text('한국어'), findsOneWidget);
  });
}
