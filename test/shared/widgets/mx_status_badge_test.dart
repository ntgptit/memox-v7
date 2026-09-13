import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

/// Handoff StatusBadge (E): dot + label, `status*` tokens, pill or bare dot.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: Center(child: child)),
    ),
  );

  Color dotColor(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(MxStatusBadge),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is DecoratedBox &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      ),
    );
    return (box.decoration as BoxDecoration).color!;
  }

  for (final (MxStatusTone tone, Color Function(AppSemanticColors) pick)
      in <(MxStatusTone, Color Function(AppSemanticColors))>[
        (MxStatusTone.isNew, (AppSemanticColors s) => s.statusNew),
        (MxStatusTone.learning, (AppSemanticColors s) => s.statusLearning),
        (MxStatusTone.reviewing, (AppSemanticColors s) => s.statusReviewing),
        (MxStatusTone.mastered, (AppSemanticColors s) => s.statusMastered),
      ]) {
    testWidgets('${tone.name} paints its status token', (tester) async {
      await pump(tester, MxStatusBadge(tone: tone, label: 'State'));
      expect(dotColor(tester), pick(const AppSemanticColors.light()));
      expect(find.text('State'), findsOneWidget);
    });
  }

  testWidgets('the dot form is a labelled 8dp mark with no text', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const MxStatusBadge(
        tone: MxStatusTone.mastered,
        label: 'Mastered',
        form: MxStatusBadgeForm.dot,
      ),
    );
    expect(find.text('Mastered'), findsNothing);
    expect(
      tester.getSize(find.byType(MxStatusBadge)),
      const Size.square(AppSizing.statusDot),
    );
    expect(tester.getSemantics(find.byType(MxStatusBadge)).label, 'Mastered');
    handle.dispose();
  });
}
