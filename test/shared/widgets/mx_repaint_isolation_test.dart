import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

/// The two components that animate forever, and what their animation costs the
/// widgets around them.
///
/// A `markNeedsPaint` travels up to the nearest repaint boundary. Without one,
/// that is the enclosing layer — so every widget sharing it repaints on every
/// frame of the spin, at 60fps, for as long as the spinner is on screen.
///
/// Measured before the boundaries were added: a sibling `CustomPaint` beside
/// `MxLoadingState` was painted once more per animation frame — 10 extra paints
/// over 10 frames. After: zero extra. These tests pin that, because the
/// regression is a deleted `RepaintBoundary` and nothing about the rendered frame
/// changes when it happens.
///
/// Counting paints rather than measuring milliseconds on purpose: a paint count
/// is deterministic, and a timing assertion in CI is a flaky test with a
/// performance-shaped name.
void main() {
  const int animationFrames = 10;

  /// Pumps [child] beside a paint counter and returns how many extra times the
  /// counter was painted while the animation ran.
  Future<int> siblingRepaintsDuringAnimation(
    WidgetTester tester,
    Widget child,
  ) async {
    final paints = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Column(
            children: <Widget>[
              // Its own `shouldRepaint` is false, so the only reason it can be
              // painted again is the layer around it being marked dirty.
              CustomPaint(
                size: const Size(50, 50),
                painter: _PaintCounter(paints),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );

    final int afterLayout = paints.length;

    for (int frame = 0; frame < animationFrames; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    return paints.length - afterLayout;
  }

  testWidgets('MxLoadingState does not repaint its neighbours', (tester) async {
    final int extraPaints = await siblingRepaintsDuringAnimation(
      tester,
      const MxLoadingState(semanticsLabel: 'Loading decks'),
    );

    expect(
      extraPaints,
      0,
      reason:
          'The spinner is sharing a layer with the widget beside it. Restore the '
          'RepaintBoundary in mx_loading_state.dart.',
    );
  });

  testWidgets('a submitting MxActionButton does not repaint the form', (
    tester,
  ) async {
    // The one that matters more: this spinner sits inside a form or a dialog, so
    // without isolation every frame repaints the fields the user is looking at.
    final int extraPaints = await siblingRepaintsDuringAnimation(
      tester,
      MxActionButton(label: 'Save deck', onPressed: () {}, isLoading: true),
    );

    expect(
      extraPaints,
      0,
      reason:
          'The button spinner is sharing a layer with its surroundings. Restore '
          'the RepaintBoundary in mx_action_button.dart.',
    );
  });

  testWidgets('an idle MxActionButton animates nothing at all', (tester) async {
    // The control. If this ever reported repaints, the assertions above would be
    // measuring something other than the spinner.
    final int extraPaints = await siblingRepaintsDuringAnimation(
      tester,
      MxActionButton(label: 'Save deck', onPressed: () {}),
    );

    expect(extraPaints, 0);
  });
}

/// Records every call to [paint] so a test can count them.
class _PaintCounter extends CustomPainter {
  _PaintCounter(this.paints);

  final List<int> paints;

  @override
  void paint(Canvas canvas, Size size) {
    paints.add(1);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF000000),
    );
  }

  /// Never for a configuration change — see the note in the test above.
  @override
  bool shouldRepaint(_PaintCounter oldDelegate) => false;
}
