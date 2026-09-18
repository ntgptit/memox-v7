import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/shared/widgets/mx_switch.dart';

/// `MxSwitch` — the bare toggle. Geometry (44×26 track, 20dp thumb, 3→21
/// travel) is FIXED per the v3 Toggle contract
/// (`docs/superpowers/plans/2026-09-18-toggle-component.md`); these tests pin
/// the numbers rather than trust the widget to keep them by construction, and
/// there is no golden here — Task 1's Global Constraint 8 defers pixel
/// comparison to a follow-up authored on Linux.
void main() {
  final colors = buildLightTheme().colorScheme;

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  BoxDecoration decorationOf(WidgetTester tester, Key key) {
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(of: find.byKey(key), matching: find.byType(DecoratedBox))
          .first,
    );
    return box.decoration as BoxDecoration;
  }

  group('behaviour', () {
    testWidgets('a tap anywhere in the 48×48 touch target toggles the value', (
      tester,
    ) async {
      final changes = <bool>[];
      await pump(tester, MxSwitch(value: false, onChanged: changes.add));

      // The corner of the touch target, deliberately outside the painted
      // 44×26 track it centres — the whole box is the target.
      final topLeft = tester.getTopLeft(find.byType(MxSwitch));
      await tester.tapAt(topLeft + const Offset(1, 1));
      await tester.pump();

      expect(changes, <bool>[true]);
    });

    testWidgets('a null onChanged disables the control: tapping does nothing', (
      tester,
    ) async {
      // Enabled twin alongside, so a tap that reached the disabled switch
      // would show as a call on its own recorder rather than as silence.
      final changes = <bool>[];
      await pump(
        tester,
        Column(
          children: <Widget>[
            const MxSwitch(value: true, onChanged: null),
            MxSwitch(value: true, onChanged: changes.add),
          ],
        ),
      );

      await tester.tap(find.byType(MxSwitch).first);
      await tester.pumpAndSettle();
      expect(changes, isEmpty);

      final thumb = find.byKey(kMxSwitchThumbKey).first;
      final trackLeft = tester.getTopLeft(find.byKey(kMxSwitchTrackKey).first);
      expect(
        tester.getTopLeft(thumb).dx - trackLeft.dx,
        21,
        reason: 'a disabled switch must not move',
      );
    });

    testWidgets('disabled paints the whole control at op-disabled opacity', (
      tester,
    ) async {
      double opacityOf() => tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(MxSwitch),
              matching: find.byType(Opacity),
            ),
          )
          .opacity;

      await pump(tester, const MxSwitch(value: true, onChanged: null));
      expect(opacityOf(), AppStateOpacity.disabled);
    });

    testWidgets('enabled paints at full opacity', (tester) async {
      await pump(tester, MxSwitch(value: true, onChanged: (_) {}));
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(MxSwitch),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 1);
    });

    testWidgets('Space activates a focused switch the same way a tap does', (
      tester,
    ) async {
      final changes = <bool>[];
      await pump(tester, MxSwitch(value: false, onChanged: changes.add));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(changes, <bool>[true]);
    });

    testWidgets('Enter activates a focused switch the same way a tap does', (
      tester,
    ) async {
      final changes = <bool>[];
      await pump(tester, MxSwitch(value: true, onChanged: changes.add));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(changes, <bool>[false]);
    });

    testWidgets('a disabled switch is not a focus stop', (tester) async {
      var toggled = false;
      await pump(
        tester,
        Column(
          children: <Widget>[
            const MxSwitch(value: false, onChanged: null),
            MxSwitch(value: false, onChanged: (_) => toggled = true),
          ],
        ),
      );

      // One Tab from nothing focused must skip the disabled switch and land
      // on the enabled one — a disabled control cannot report handling
      // Space/Enter if it was never able to receive them.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(toggled, isTrue);
    });
  });

  group('semantics', () {
    testWidgets('off: untoggled, enabled, carries the label', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        MxSwitch(value: false, onChanged: (_) {}, semanticLabel: 'Reminders'),
      );

      final node = tester.getSemantics(find.byType(MxSwitch));
      expect(node.flagsCollection.isToggled, Tristate.isFalse);
      expect(node.flagsCollection.isEnabled, Tristate.isTrue);
      expect(node.label, 'Reminders');
      handle.dispose();
    });

    testWidgets('on: toggled', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, MxSwitch(value: true, onChanged: (_) {}));

      final node = tester.getSemantics(find.byType(MxSwitch));
      expect(node.flagsCollection.isToggled, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('a null onChanged reports disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, const MxSwitch(value: true, onChanged: null));

      final node = tester.getSemantics(find.byType(MxSwitch));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('an enabled switch offers the tap action', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, MxSwitch(value: true, onChanged: (_) {}));
      expect(
        tester
            .getSemantics(find.byType(MxSwitch))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('a disabled switch offers no tap action', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, const MxSwitch(value: true, onChanged: null));
      expect(
        tester
            .getSemantics(find.byType(MxSwitch))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('no semanticLabel leaves the label empty, not "null"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, MxSwitch(value: false, onChanged: (_) {}));

      final node = tester.getSemantics(find.byType(MxSwitch));
      expect(node.label, isEmpty);
      handle.dispose();
    });
  });

  group('geometry', () {
    testWidgets('the touch target floors at 48×48 around a 44×26 track', (
      tester,
    ) async {
      await pump(tester, MxSwitch(value: false, onChanged: (_) {}));

      expect(
        tester.getSize(find.byType(MxSwitch)),
        const Size(AppSizing.touchTarget, AppSizing.touchTarget),
      );
      expect(tester.getSize(find.byKey(kMxSwitchTrackKey)), const Size(44, 26));
      expect(tester.getSize(find.byKey(kMxSwitchThumbKey)), const Size(20, 20));
    });

    testWidgets('off: the thumb rests 3dp from the track\'s left edge', (
      tester,
    ) async {
      await pump(tester, MxSwitch(value: false, onChanged: (_) {}));

      final trackLeft = tester.getTopLeft(find.byKey(kMxSwitchTrackKey)).dx;
      final thumbLeft = tester.getTopLeft(find.byKey(kMxSwitchThumbKey)).dx;
      expect(thumbLeft - trackLeft, 3);
    });

    testWidgets('on: the thumb travels to 21dp from the track\'s left edge', (
      tester,
    ) async {
      await pump(tester, MxSwitch(value: true, onChanged: (_) {}));

      final trackLeft = tester.getTopLeft(find.byKey(kMxSwitchTrackKey)).dx;
      final thumbLeft = tester.getTopLeft(find.byKey(kMxSwitchThumbKey)).dx;
      expect(thumbLeft - trackLeft, 21);
    });
  });

  group('colour — the registry, not app_toggle_themes.dart', () {
    testWidgets('off track is surfaceContainerHighest', (tester) async {
      await pump(tester, MxSwitch(value: false, onChanged: (_) {}));
      expect(
        decorationOf(tester, kMxSwitchTrackKey).color,
        colors.surfaceContainerHighest,
      );
    });

    testWidgets('on track is primary', (tester) async {
      // A fresh pump, not a second pump reusing the first test's tree: the
      // controller starts at its target value in `initState`, where updating
      // an existing `MxSwitch` in place would animate to it over 160ms
      // instead.
      await pump(tester, MxSwitch(value: true, onChanged: (_) {}));
      expect(decorationOf(tester, kMxSwitchTrackKey).color, colors.primary);
    });

    testWidgets('the thumb is surfaceBright off', (tester) async {
      await pump(tester, MxSwitch(value: false, onChanged: (_) {}));
      expect(
        decorationOf(tester, kMxSwitchThumbKey).color,
        colors.surfaceBright,
      );
    });

    testWidgets('the thumb is surfaceBright on — no on/off split', (
      tester,
    ) async {
      await pump(tester, MxSwitch(value: true, onChanged: (_) {}));
      expect(
        decorationOf(tester, kMxSwitchThumbKey).color,
        colors.surfaceBright,
      );
    });
  });

  group('state layer', () {
    Finder overlayFinder(Color expected) => find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == expected,
    );

    testWidgets('pressing washes the thumb with the control overlay', (
      tester,
    ) async {
      final expected = AppInteractionStates.controlOverlay(
        colors,
      ).resolve(<WidgetState>{WidgetState.pressed})!;
      await pump(tester, MxSwitch(value: false, onChanged: (_) {}));
      expect(overlayFinder(expected), findsNothing, reason: 'at rest');

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(MxSwitch)),
      );
      await tester.pump();
      expect(overlayFinder(expected), findsOneWidget);

      await gesture.up();
      await tester.pump();
      expect(overlayFinder(expected), findsNothing, reason: 'after release');
    });

    testWidgets('pressing a disabled switch paints no wash', (tester) async {
      final pressed = AppInteractionStates.controlOverlay(
        colors,
      ).resolve(<WidgetState>{WidgetState.pressed})!;
      await pump(tester, const MxSwitch(value: false, onChanged: null));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(MxSwitch)),
      );
      await tester.pump();
      expect(overlayFinder(pressed), findsNothing);
      await gesture.up();
    });

    testWidgets('hovering washes the thumb with the control overlay', (
      tester,
    ) async {
      final expected = AppInteractionStates.controlOverlay(
        colors,
      ).resolve(<WidgetState>{WidgetState.hovered})!;
      await pump(tester, MxSwitch(value: false, onChanged: (_) {}));

      // `FocusableActionDetector` only shows a hover highlight in
      // `FocusHighlightMode.traditional` — a mouse move alone never switches
      // to it (only a touch/stylus event or a key event does; see
      // `FocusManager.handlePointerEvent`), and the test platform's default
      // mode is touch. A Tab first puts the app in the mode a mouse user's
      // hover is actually shown in.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.byType(MxSwitch)));
      await tester.pumpAndSettle();
      expect(overlayFinder(expected), findsOneWidget);

      await gesture.moveTo(const Offset(500, 500));
      await tester.pumpAndSettle();
      expect(overlayFinder(expected), findsNothing);
    });
  });
}
