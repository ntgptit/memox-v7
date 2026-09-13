import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/shared/widgets/mx_mastery_ring.dart';

/// Handoff MasteryRing (E): 40 × 3px. Colour follows BR-88 (D8).
void main() {
  Future<MxMasteryRingPainter> pump(
    WidgetTester tester, {
    required double value,
    required bool isComplete,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Center(
            child: MxMasteryRing(
              value: value,
              isComplete: isComplete,
              semanticsLabel: 'Learned',
              semanticsValue: '${(value * 100).round()}%',
            ),
          ),
        ),
      ),
    );

    return tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(MxMasteryRing),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as MxMasteryRingPainter;
  }

  testWidgets('40 square, 3px stroke', (tester) async {
    final painter = await pump(tester, value: 0.4, isComplete: false);
    expect(
      tester.getSize(find.byType(MxMasteryRing)),
      const Size.square(AppSizing.masteryRing),
    );
    expect(painter.stroke, AppStroke.ring);
    expect(AppStroke.ring, 3);
  });

  testWidgets('primary until complete, mastery at complete (BR-88)', (
    tester,
  ) async {
    final theme = buildLightTheme();
    expect(
      (await pump(tester, value: 0.99, isComplete: false)).fill,
      theme.colorScheme.primary,
    );
    expect(
      (await pump(tester, value: 1, isComplete: true)).fill,
      const AppSemanticColors.light().mastery,
    );
  });

  testWidgets('the track is the progress track token', (tester) async {
    final painter = await pump(tester, value: 0.5, isComplete: false);
    expect(painter.track, const AppSemanticColors.light().progressTrack);
  });

  testWidgets('speaks its label and value', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, value: 0.5, isComplete: false);
    final node = tester.getSemantics(find.byType(MxMasteryRing));
    expect(node.label, 'Learned');
    expect(node.value, '50%');
    handle.dispose();
  });
}
