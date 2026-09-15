import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';

/// `MxPillButton` — the app's one-of-N control.
///
/// The selection semantics are the reason this wraps `ChoiceChip` instead of an
/// `InkWell`, so they are what most of this file asserts: a pill that looks
/// selected and does not *say* it is selected is the failure a hand-rolled
/// version ships with.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget pill, {
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Center(child: pill),
          ),
        ),
      ),
    );
  }

  group('interaction', () {
    testWidgets('reports a press', (tester) async {
      var presses = 0;
      await pump(
        tester,
        MxPillButton(
          label: 'A-Z',
          isSelected: false,
          onPressed: () => presses += 1,
        ),
      );

      await tester.tap(find.byType(MxPillButton));
      await tester.pump();

      expect(presses, 1);
    });

    testWidgets('reports a press even when already selected', (tester) async {
      // A toggle's selected pill is what switches back. A `ChoiceChip` that
      // swallowed the tap on the selected value would strand the user on the
      // filtered view with no way out.
      var presses = 0;
      await pump(
        tester,
        MxPillButton(
          label: 'A-Z',
          isSelected: true,
          onPressed: () => presses += 1,
        ),
      );

      await tester.tap(find.byType(MxPillButton));
      await tester.pump();

      expect(presses, 1);
    });

    testWidgets('a null callback disables it', (tester) async {
      await pump(
        tester,
        const MxPillButton(label: 'A-Z', isSelected: false, onPressed: null),
      );

      expect(
        tester.widget<ChoiceChip>(find.byType(ChoiceChip)).onSelected,
        isNull,
      );
    });
  });

  group('semantics', () {
    testWidgets('announces its selected state', (tester) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxPillButton(label: 'Due only', isSelected: true, onPressed: () {}),
      );

      expect(
        tester.getSemantics(find.byType(ChoiceChip)),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
          hasFocusAction: true,
          label: 'Due only',
        ),
      );
      handle.dispose();
    });

    testWidgets('an abbreviation is replaced, not appended', (tester) async {
      // `A-Z` is two letters read aloud. The expansion has to *replace* it, or a
      // screen reader announces both and the control names itself twice.
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxPillButton(
          label: 'A-Z',
          semanticLabel: 'Sorted by name. Activate to sort by newest first.',
          isSelected: true,
          onPressed: () {},
        ),
      );

      expect(
        find.bySemanticsLabel(
          'Sorted by name. Activate to sort by newest first.',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('A-Z'), findsNothing);
      handle.dispose();
    });

    testWidgets('without an override the visible label is the name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxPillButton(label: 'All decks', isSelected: false, onPressed: () {}),
      );

      expect(find.bySemanticsLabel('All decks'), findsOneWidget);
      handle.dispose();
    });
  });

  group('layout', () {
    testWidgets('meets the minimum touch target', (tester) async {
      await pump(
        tester,
        MxPillButton(label: 'A-Z', isSelected: false, onPressed: () {}),
      );

      // A chip is 32 high on its own. `materialTapTargetSize.padded` is what
      // takes it to the guideline minimum, and this is the assertion that stops
      // someone removing it for looking redundant.
      final size = tester.getSize(find.byType(MxPillButton));
      expect(size.height, greaterThanOrEqualTo(AppSizing.touchTarget));
    });

    testWidgets('survives 2.0x text without overflowing', (tester) async {
      await pump(
        tester,
        MxPillButton(
          label: 'Tất cả bộ thẻ',
          icon: Icons.filter_list,
          isSelected: true,
          onPressed: () {},
        ),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('the touch target grows on the narrow axis too', (
      tester,
    ) async {
      // A one-glyph pill paints ~33 wide. The 48 floor is both sides, and it
      // is the widget's own now rather than `chip.dart:1493`'s (#434 P3-1).
      await pump(
        tester,
        MxPillButton(label: 'A', isSelected: false, onPressed: () {}),
      );

      final size = tester.getSize(find.byType(MxPillButton));
      expect(size.width, greaterThanOrEqualTo(AppSizing.touchTarget));
    });

    testWidgets('a tap in the padding still presses the pill', (tester) async {
      // The target is a redirecting pad: a finger that lands beside the
      // painted shape is handed to the chip's centre, so the chip's own ink and
      // callback run. Without the redirect the padding would be dead area.
      var presses = 0;
      await pump(
        tester,
        MxPillButton(label: 'A', isSelected: false, onPressed: () => presses++),
      );

      // The short axis: the pill paints 34 tall inside the 48 box. (On the
      // wide axis the 16dp leading slot already carries even a one-glyph
      // pill past 48, so there is no horizontal padding to land in.)
      final Rect target = tester.getRect(find.byType(MxPillButton));
      final Rect painted = tester.getRect(find.byType(ChoiceChip));
      expect(painted.top, greaterThan(target.top + 2));

      await tester.tapAt(Offset(target.center.dx, target.top + 2));
      await tester.pumpAndSettle();
      expect(presses, 1);
    });

    testWidgets('an icon does not replace the label', (tester) async {
      // The icon is decoration. A pill that dropped its text when given one
      // would be an icon button with a bigger hit area, which already exists.
      await pump(
        tester,
        MxPillButton(
          label: 'Due only',
          icon: Icons.filter_list,
          isSelected: false,
          onPressed: () {},
        ),
      );

      expect(find.text('Due only'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });
  });

  group('selection shape', () {
    // M100.36 4M / #434 P1-3: selection is a tick in a slot that is laid out
    // in both states, so it is never colour alone and never a reflow.
    Future<double> paintedWidth(
      WidgetTester tester, {
      required bool isSelected,
      IconData? icon,
    }) async {
      await pump(
        tester,
        MxPillButton(
          label: 'Due',
          icon: icon,
          isSelected: isSelected,
          onPressed: () {},
        ),
      );

      return tester.getSize(find.byType(ChoiceChip)).width;
    }

    testWidgets('a selected pill carries a tick', (tester) async {
      await pump(
        tester,
        MxPillButton(label: 'Due', isSelected: true, onPressed: () {}),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('an unselected pill carries no tick', (tester) async {
      await pump(
        tester,
        MxPillButton(label: 'Due', isSelected: false, onPressed: () {}),
      );

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('the tick replaces the caller icon in the same slot', (
      tester,
    ) async {
      await pump(
        tester,
        MxPillButton(
          label: 'Due',
          icon: Icons.schedule,
          isSelected: true,
          onPressed: () {},
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsNothing);
    });

    for (final IconData? icon in <IconData?>[null, Icons.schedule]) {
      testWidgets(
        'toggling ${icon == null ? 'a plain' : 'an iconed'} pill does not '
        'change its width',
        (tester) async {
          final off = await paintedWidth(tester, isSelected: false, icon: icon);
          final on = await paintedWidth(tester, isSelected: true, icon: icon);

          expect(on, off, reason: 'the row reflows on every selection');
        },
      );
    }
  });
}
