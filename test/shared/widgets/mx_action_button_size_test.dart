import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

/// What each size *draws*, and the floor none of them may take with it.
///
/// **The body and the target are two boxes, and the whole point of the enum is
/// that they can differ.** `MaterialTapTargetSize.padded` makes the widget the
/// target and the ink `Material` inside it the body, so a test that measures
/// the outer box reports every size as 48 and proves nothing. This one
/// measures both and names which is which.
void main() {
  final ThemeData light = buildLightTheme();

  Future<(double body, double target)> pump(
    WidgetTester tester,
    MxActionButtonSize size,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: light,
        home: Scaffold(
          body: Center(
            child: MxActionButton(label: 'Study', size: size, onPressed: _noop),
          ),
        ),
      ),
    );

    final button = find.byType(MxActionButton);
    final ink = find
        .descendant(of: button, matching: find.byType(Material))
        .first;

    return (tester.getRect(ink).height, tester.getRect(button).height);
  }

  test('the three bodies are the three tokens, in order', () {
    // Stated as an ordering rather than three numbers: what the enum promises
    // is a ladder, and a ladder that stops descending is the bug.
    expect(AppSizing.controlDense, lessThan(AppSizing.controlCompact));
    expect(AppSizing.controlCompact, lessThan(AppSizing.touchTarget));
  });

  testWidgets('standard draws its target', (tester) async {
    final (body, target) = await pump(tester, MxActionButtonSize.standard);

    expect(body, AppSizing.touchTarget);
    expect(target, greaterThanOrEqualTo(AppSizing.touchTarget));
  });

  testWidgets('compact draws 40', (tester) async {
    final (body, target) = await pump(tester, MxActionButtonSize.compact);

    expect(body, AppSizing.controlCompact);
    expect(target, greaterThanOrEqualTo(AppSizing.touchTarget));
  });

  testWidgets('dense draws 32 and the finger still gets 48', (tester) async {
    // The size added at M100.77. It is a return to a body the 2026-08-20
    // review moved *away* from — "40 is on the 4px grid and clears the 32 the
    // pill used to paint" — so it arrived as an option beside `compact` rather
    // than as an edit to it. The floor is what is not optional, and it is
    // measured here rather than trusted to the sentence above.
    final (body, target) = await pump(tester, MxActionButtonSize.dense);

    expect(body, AppSizing.controlDense);
    expect(
      target,
      greaterThanOrEqualTo(AppSizing.touchTarget),
      reason: 'a smaller body must never mean a smaller target',
    );
  });

  testWidgets('every size keeps the floor at 2.0x text scale', (tester) async {
    // The body grows past its token when the label does; the floor must hold
    // at both ends of that.
    for (final size in MxActionButtonSize.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: Center(
                child: MxActionButton(
                  label: 'Study',
                  size: size,
                  onPressed: _noop,
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getRect(find.byType(MxActionButton)).height,
        greaterThanOrEqualTo(AppSizing.touchTarget),
        reason: '$size drops below the touch floor at 2.0x',
      );
    }
  });
}

void _noop() {}
