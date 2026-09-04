import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

/// A20.1 P1-04 — the breadcrumb fold shows keyboard focus like every other
/// control in the app.
void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: MxBreadcrumb(
            items: <MxBreadcrumbItem>[
              for (var i = 0; i < 6; i++)
                MxBreadcrumbItem(
                  label: 'Level $i',
                  onTap: i == 5 ? null : () {},
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The foreground ring drawn around the fold, if any.
  BoxDecoration? ringAroundFold(WidgetTester tester) {
    final fold = tester.getCenter(find.byIcon(Icons.more_horiz));
    for (final element
        in find
            .byWidgetPredicate(
              (Widget w) =>
                  w is DecoratedBox &&
                  w.position == DecorationPosition.foreground,
            )
            .evaluate()) {
      final box = element.renderObject! as RenderBox;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (!rect.contains(fold)) continue;
      final decoration = (element.widget as DecoratedBox).decoration;
      if (decoration is BoxDecoration && decoration.border != null) {
        return decoration;
      }
    }
    return null;
  }

  testWidgets('no ring at rest; the ring appears once Tab reaches the fold', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget, reason: 'no fold');
    expect(ringAroundFold(tester), isNull);

    BoxDecoration? ring;
    for (var i = 0; i < 6 && ring == null; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      ring = ringAroundFold(tester);
    }

    expect(ring, isNotNull, reason: 'Tab never lit the fold');
    final side = ring!.border!.top;
    expect(side.width, AppStroke.focus);
    expect(
      side.color,
      AppInteractionStates.focusIndicator(buildLightTheme().colorScheme).color,
    );
  });
}
