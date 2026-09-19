import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_tap_target.dart';

enum _Choice { first, second, third }

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    TextDirection textDirection = TextDirection.ltr,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Directionality(
          textDirection: textDirection,
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  MxSegmentedTray<_Choice> tray({
    _Choice selected = _Choice.first,
    ValueChanged<_Choice>? onChanged,
    MxSegmentedTrayVariant variant = MxSegmentedTrayVariant.settings,
    List<MxSegmentedTrayOption<_Choice>>? options,
  }) => MxSegmentedTray<_Choice>(
    options:
        options ??
        const <MxSegmentedTrayOption<_Choice>>[
          MxSegmentedTrayOption<_Choice>(value: _Choice.first, label: 'First'),
          MxSegmentedTrayOption<_Choice>(
            value: _Choice.second,
            label: 'Second',
          ),
        ],
    selected: selected,
    variant: variant,
    onChanged: onChanged ?? (_) {},
  );

  final Finder trayFinder = find.byType(MxTapTarget);

  group('MxSegmentedTray', () {
    testWidgets('reports the tapped typed choice', (tester) async {
      _Choice? changed;
      await pump(tester, tray(onChanged: (value) => changed = value));

      await tester.tap(find.text('Second'));

      expect(changed, _Choice.second);
    });

    testWidgets('announces the selected mutually-exclusive option', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, tray());

      expect(
        tester.getSemantics(find.text('First')),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasSelectedState: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          label: 'First',
        ),
      );
      final unselected = tester
          .getSemantics(find.text('Second'))
          .getSemanticsData();
      expect(unselected.flagsCollection.isSelected, Tristate.isFalse);
      expect(unselected.hasAction(SemanticsAction.tap), isTrue);
      expect(
        unselected.flagsCollection.isInMutuallyExclusiveGroup,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('keeps a 32dp thumb inside the 48dp target', (tester) async {
      await pump(tester, tray());

      expect(tester.getSize(trayFinder).height, AppSizing.touchTarget);
      expect(tester.getSize(find.byKey(MxSegmentedTray.thumbKey)).height, 32);
      expect(tester.getRect(find.byKey(MxSegmentedTray.thumbKey)).height, 32);
    });

    testWidgets('uses the 4, 2, 12 and 8 geometry contract', (tester) async {
      await pump(tester, tray());

      final trayRect = tester.getRect(find.byKey(MxSegmentedTray.surfaceKey));
      final first = tester.getRect(find.text('First'));
      final second = tester.getRect(find.text('Second'));
      final thumb = tester.getRect(find.byKey(MxSegmentedTray.thumbKey));

      expect(first.left - trayRect.left, 16);
      expect(second.left - first.right, 26);
      expect(thumb.left - trayRect.left, 4);
      expect(thumb.height, 32);
      expect(
        tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byKey(MxSegmentedTray.thumbKey),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration,
        isA<BoxDecoration>().having(
          (decoration) => decoration.borderRadius,
          'thumb radius',
          BorderRadius.circular(8),
        ),
      );
    });

    testWidgets('is intrinsic-width rather than stretching to its parent', (
      tester,
    ) async {
      await pump(tester, SizedBox(width: 300, child: tray()));

      expect(tester.getSize(trayFinder).width, lessThan(300));
    });

    testWidgets('shows the canonical focus ring on keyboard focus', (
      tester,
    ) async {
      await pump(tester, tray());

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final ring = tester.widget<DecoratedBox>(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is DecoratedBox &&
                  widget.position == DecorationPosition.foreground,
            )
            .first,
      );
      expect((ring.decoration as BoxDecoration).border, isNotNull);
    });

    testWidgets('does not overflow in RTL at text scale 2', (tester) async {
      await pump(
        tester,
        tray(
          options: const <MxSegmentedTrayOption<_Choice>>[
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.first,
              label: 'First',
            ),
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.second,
              label: 'Second',
            ),
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.third,
              label: 'Third',
            ),
          ],
        ),
        textDirection: TextDirection.rtl,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });

    test('requires two or three options', () {
      expect(
        () => tray(
          options: const <MxSegmentedTrayOption<_Choice>>[
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.first,
              label: 'First',
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => tray(
          options: const <MxSegmentedTrayOption<_Choice>>[
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.first,
              label: 'First',
            ),
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.second,
              label: 'Second',
            ),
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.third,
              label: 'Third',
            ),
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.first,
              label: 'Fourth',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
