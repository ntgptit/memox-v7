import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

/// The v3 Fab contract's geometry and its keyboard-focus ring.
///
/// Pattern copied from `mx_breadcrumb_focus_test.dart`: a real `Tab` key event
/// moves focus, because `MxFocusRing` only paints for
/// `FocusHighlightMode.traditional` — the mode Flutter switches to on the
/// first real key event, not on a programmatic `requestFocus()`.
void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: MxFab(icon: Icons.add, label: 'Add', onPressed: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The foreground ring drawn around the FAB, if any.
  BoxDecoration? ringAroundFab(WidgetTester tester) {
    for (final element
        in find
            .byWidgetPredicate(
              (Widget w) =>
                  w is DecoratedBox &&
                  w.position == DecorationPosition.foreground,
            )
            .evaluate()) {
      final decoration = (element.widget as DecoratedBox).decoration;
      if (decoration is BoxDecoration && decoration.border != null) {
        return decoration;
      }
    }
    return null;
  }

  testWidgets('no ring at rest; the ring appears once Tab reaches the FAB', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(ringAroundFab(tester), isNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final ring = ringAroundFab(tester);
    expect(ring, isNotNull, reason: 'Tab never lit the FAB');
    final side = ring!.border!.top;
    expect(side.width, AppStroke.focus);
    // `onPrimary`, not `primary` — the FAB's own fill IS `primary`, so a
    // `primary` ring would be invisible on it (1.00:1). See
    // `AppInteractionStates.focusIndicatorOf`'s doc comment.
    final scheme = buildLightTheme().colorScheme;
    expect(
      side.color,
      AppInteractionStates.focusIndicatorOf(scheme.onPrimary).color,
    );
    expect(side.color, isNot(scheme.primary));
  });

  testWidgets('the FAB paints at the fixed 52x52 v3 size, glyph at 20dp', (
    tester,
  ) async {
    await pump(tester);

    expect(
      tester.getSize(find.byType(FloatingActionButton)),
      const Size(AppSizing.fab, AppSizing.fab),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.add));
    final IconThemeData merged = IconTheme.of(
      tester.element(find.byIcon(Icons.add)),
    );
    expect(icon.size ?? merged.size, AppIconSize.mdCompact);
  });
}
