import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';
import 'package:memox/shared/widgets/mx_tap_target.dart';

const Key _valueColumnKey = ValueKey<String>('mx-stepper-value-column');
const Key _decrementPaintKey = ValueKey<String>('mx-stepper-decrement-paint');

void main() {
  Future<void> pumpStepper(
    WidgetTester tester, {
    int value = 4,
    VoidCallback? onDecrement,
    VoidCallback? onIncrement,
    bool isInvalid = false,
    bool isBusy = false,
    bool isEnabled = true,
    bool isDark = false,
    TextDirection textDirection = TextDirection.ltr,
    Size surface = const Size(360, 640),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Directionality(
              textDirection: textDirection,
              child: Scaffold(
                body: Center(
                  child: MxStepper(
                    value: value,
                    decrementSemanticLabel: 'Decrease quantity',
                    incrementSemanticLabel: 'Increase quantity',
                    onDecrement: onDecrement,
                    onIncrement: onIncrement,
                    isInvalid: isInvalid,
                    isBusy: isBusy,
                    isEnabled: isEnabled,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (isBusy) {
      await tester.pump();
      return;
    }
    await tester.pumpAndSettle();
  }

  group('MxStepper geometry and theme roles', () {
    testWidgets('keeps 36dp paint inside 48dp targets and 4dp gaps', (
      WidgetTester tester,
    ) async {
      await pumpStepper(tester, onDecrement: () {}, onIncrement: () {});
      expect(
        tester.getSize(find.byKey(_decrementPaintKey)),
        const Size(36, 36),
      );
      for (var index = 0; index < 2; index++) {
        final size = tester.getSize(find.byType(MxTapTarget).at(index));
        expect(size.width, AppSizing.touchTarget);
        expect(size.height, AppSizing.touchTarget);
      }
      final decrement = tester.getRect(find.byType(MxTapTarget).first);
      final value = tester.getRect(find.byKey(_valueColumnKey));
      final increment = tester.getRect(find.byType(MxTapTarget).last);
      expect(value.width, greaterThanOrEqualTo(AppSizing.touchTarget));
      expect(value.left - decrement.right, AppSpacing.xs);
      expect(increment.left - value.right, AppSpacing.xs);
    });

    testWidgets('binds paint and value ink directly to theme roles', (
      WidgetTester tester,
    ) async {
      for (final isDark in <bool>[false, true]) {
        await pumpStepper(
          tester,
          isDark: isDark,
          onDecrement: () {},
          onIncrement: () {},
        );
        final colors = Theme.of(
          tester.element(find.byType(MxStepper)),
        ).colorScheme;
        expect(
          tester.widget<Material>(find.byKey(_decrementPaintKey)).color,
          colors.surfaceContainer,
        );
        expect(
          tester.widget<Text>(find.text('4')).style!.color,
          colors.onSurface,
        );
        final validDecoration =
            tester.widget<DecoratedBox>(find.byKey(_valueColumnKey)).decoration
                as BoxDecoration;
        final validBorder = validDecoration.border! as Border;
        expect(validBorder.top.width, 1);
        expect(validBorder.top.color.a, 0);
        await pumpStepper(
          tester,
          isDark: isDark,
          isInvalid: true,
          onDecrement: () {},
          onIncrement: () {},
        );
        final invalidColors = Theme.of(
          tester.element(find.byType(MxStepper)),
        ).colorScheme;
        final decoration =
            tester.widget<DecoratedBox>(find.byKey(_valueColumnKey)).decoration
                as BoxDecoration;
        final border = decoration.border! as Border;
        expect(border.top.width, 1);
        expect(border.top.color, invalidColors.error);
        expect(
          tester.widget<Text>(find.text('4')).style!.color,
          invalidColors.error,
        );
      }
    });

    testWidgets('invalid and busy states preserve value-column geometry', (
      WidgetTester tester,
    ) async {
      await pumpStepper(
        tester,
        value: 123456789,
        onDecrement: () {},
        onIncrement: () {},
      );
      final resting = tester.getRect(find.byKey(_valueColumnKey));
      await pumpStepper(
        tester,
        value: 123456789,
        isInvalid: true,
        onDecrement: () {},
        onIncrement: () {},
      );
      expect(tester.getRect(find.byKey(_valueColumnKey)).size, resting.size);
      await pumpStepper(
        tester,
        value: 123456789,
        isBusy: true,
        onDecrement: () {},
        onIncrement: () {},
      );
      expect(tester.getRect(find.byKey(_valueColumnKey)).size, resting.size);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<Visibility>(find.byType(Visibility)).visible,
        isFalse,
      );
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .color,
        Theme.of(tester.element(find.byType(MxStepper))).colorScheme.primary,
      );
    });
  });

  group('MxStepper interaction and semantics', () {
    testWidgets('fires enabled callbacks from tap and keyboard activation', (
      WidgetTester tester,
    ) async {
      var decrements = 0;
      var increments = 0;
      await pumpStepper(
        tester,
        onDecrement: () => decrements++,
        onIncrement: () => increments++,
      );
      await tester.tap(find.bySemanticsLabel('Decrease quantity'));
      await tester.pumpAndSettle();
      expect(decrements, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(decrements, 2);
      await tester.tap(find.bySemanticsLabel('Increase quantity'));
      await tester.pumpAndSettle();
      expect(increments, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Decrease quantity')),
        matchesSemantics(
          label: 'Decrease quantity',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('null callbacks and global disabled state block interaction', (
      WidgetTester tester,
    ) async {
      var increments = 0;
      await pumpStepper(tester, onIncrement: () => increments++);
      await tester.tap(find.bySemanticsLabel('Decrease quantity'));
      await tester.tap(find.bySemanticsLabel('Increase quantity'));
      await tester.pumpAndSettle();
      expect(increments, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Decrease quantity')),
        matchesSemantics(isButton: true, hasEnabledState: true),
      );
      await pumpStepper(
        tester,
        isEnabled: false,
        onDecrement: () {},
        onIncrement: () => increments++,
      );
      await tester.tap(find.bySemanticsLabel('Increase quantity'));
      await tester.pumpAndSettle();
      expect(increments, 1);
      expect(
        tester.widget<Opacity>(find.byType(Opacity)).opacity,
        AppStateOpacity.disabled,
      );
    });
  });

  group('MxStepper resilience', () {
    testWidgets('mirrors its action order for RTL', (
      WidgetTester tester,
    ) async {
      await pumpStepper(
        tester,
        textDirection: TextDirection.rtl,
        onDecrement: () {},
        onIncrement: () {},
      );
      expect(
        tester.getTopLeft(find.bySemanticsLabel('Decrease quantity')).dx,
        greaterThan(
          tester.getTopLeft(find.bySemanticsLabel('Increase quantity')).dx,
        ),
      );
    });

    testWidgets('survives a long value at 320dp and text scale 2.0', (
      WidgetTester tester,
    ) async {
      await pumpStepper(
        tester,
        value: -123456789,
        surface: const Size(320, 568),
        textScale: 2,
        onDecrement: () {},
        onIncrement: () {},
      );
      expect(tester.takeException(), isNull);
    });
  });
}
