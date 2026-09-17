import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_pressable.dart';

import '../../support/color_math.dart';

/// The three things the pressable exists to make non-optional: the ripple's
/// Material, the 48 floor, and the closed shape list.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('floors its content at the touch target', (tester) async {
    // 12 tall on its own — the details toggle drew ~36 before migration, and
    // nothing failed. The floor is the widget's job now, so a short child is
    // the case that proves it.
    await tester.pumpWidget(
      host(
        MxPressable(
          onTap: () {},
          child: const SizedBox(height: 12, width: 120),
        ),
      ),
    );

    final size = tester.getSize(find.byType(MxPressable));
    expect(size.height, greaterThanOrEqualTo(AppSizing.touchTarget));
  });

  testWidgets('carries its own transparent Material, so the ripple works '
      'inside a painted container', (tester) async {
    // A DecoratedBox parent is exactly the setting where a bare InkWell's
    // ripple vanishes under the fill — the reason two call sites hand-wrote
    // the Material(transparency) pair this widget replaces.
    await tester.pumpWidget(
      host(
        DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF888888)),
          child: MxPressable(onTap: () {}, child: const Text('tap')),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(MxPressable),
        matching: find.byType(Material),
      ),
    );
    expect(material.type, MaterialType.transparency);
    expect(
      find.descendant(
        of: find.byType(MxPressable),
        matching: find.byType(InkWell),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the shape steps are AppRadius, and none means square', (
    tester,
  ) async {
    // The enum's promise is that a call site names a step instead of shipping
    // a BorderRadius — so the mapping is the contract, not an implementation
    // detail.
    expect(MxPressableShape.none.borderRadius, isNull);
    expect(
      MxPressableShape.sm.borderRadius,
      BorderRadius.circular(AppRadius.sm),
    );
    expect(
      MxPressableShape.md.borderRadius,
      BorderRadius.circular(AppRadius.md),
    );

    await tester.pumpWidget(
      host(
        MxPressable(
          onTap: () {},
          shape: MxPressableShape.sm,
          child: const Text('tap'),
        ),
      ),
    );
    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.borderRadius, BorderRadius.circular(AppRadius.sm));
  });

  testWidgets('tap and long-press reach the caller', (tester) async {
    var taps = 0;
    var longPresses = 0;
    await tester.pumpWidget(
      host(
        MxPressable(
          onTap: () => taps += 1,
          onLongPress: () => longPresses += 1,
          child: const Text('tap'),
        ),
      ),
    );

    await tester.tap(find.byType(MxPressable));
    await tester.longPress(find.byType(MxPressable));
    expect(taps, 1);
    expect(longPresses, 1);
  });

  testWidgets('a null onTap disables the surface', (tester) async {
    await tester.pumpWidget(
      host(const MxPressable(onTap: null, child: Text('off'))),
    );

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNull);
  });

  testWidgets('keyboard focus draws the shared ring, and it moves nothing', (
    tester,
  ) async {
    // #431 P1-3: five feature rows gave a keyboard user a ~1.15:1 wash and no
    // ring, where WCAG 1.4.11 asks 3:1.
    await tester.pumpWidget(
      host(
        MxPressable(
          onTap: () {},
          child: const SizedBox(height: 40, width: 200, child: Text('row')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final atRest = tester.getRect(find.byType(MxPressable));

    BorderSide? ring() {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MxPressable),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final border = (box.decoration as BoxDecoration).border;
      return border == null ? null : (border as Border).top;
    }

    expect(ring(), isNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final theme = buildLightTheme();
    expect(ring()?.width, AppStroke.focus, reason: 'no ring on focus');
    expect(
      contrast(ring()!.color, theme.colorScheme.surface),
      greaterThanOrEqualTo(3.0),
    );
    expect(tester.getRect(find.byType(MxPressable)), atRest);
  });

  testWidgets('an inert surface is not a focus stop', (tester) async {
    await tester.pumpWidget(
      host(const MxPressable(onTap: null, child: Text('row'))),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MxPressable),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((box.decoration as BoxDecoration).border, isNull);
  });
}
