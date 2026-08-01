import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_interaction_states.dart';
import 'package:memox/core/theme/app_stroke.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';

import '../../support/ink_probe.dart';

/// `MxListTile` — the app's row, and the interaction states it grew when the
/// common contract landed.
///
/// Its own file for the reason `mx_card_test.dart` is: adding the state tests
/// pushed `mx_surface_components_test.dart` past the 400-line guard, and the
/// seam is clean — nothing here touches the dialog or the sheet.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool isDark = false,
    Size surface = const Size(360, 640),
    double textScale = 1,
    bool settle = true,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: Builder(
          // `copyWith`, never a fresh `MediaQueryData`: constructing one
          // zeroes `size`, `padding` and `viewInsets`, so the widget under
          // test is told the screen is 0x0 while `tester.view` says
          // otherwise. Anything that reads the width then branches on a
          // number no device reports.
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
      return;
    }
    await tester.pump();
  }

  const long =
      'A deck name long enough that it has to wrap or be cut off, twice over';
  group('MxListTile', () {
    testWidgets('renders every slot it was given', (tester) async {
      await pump(
        tester,
        const MxListTile(
          title: 'Academic Word List',
          subtitle: '20 of 570 learned',
          leading: Icon(Icons.style_outlined),
          trailing: Icon(Icons.chevron_right),
        ),
      );

      expect(find.text('Academic Word List'), findsOneWidget);
      expect(find.text('20 of 570 learned'), findsOneWidget);
      expect(find.byIcon(Icons.style_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('tap fires once', (tester) async {
      var taps = 0;

      await pump(tester, MxListTile(title: 'Deck', onTap: () => taps++));
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('disabled fires nothing', (tester) async {
      var taps = 0;

      await pump(
        tester,
        MxListTile(title: 'Deck', isEnabled: false, onTap: () => taps++),
      );
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(taps, 0);
    });

    testWidgets('selected is carried through to the tile', (tester) async {
      await pump(tester, const MxListTile(title: 'Deck', isSelected: true));

      expect(tester.widget<ListTile>(find.byType(ListTile)).selected, isTrue);
    });

    testWidgets('a long title truncates rather than overflowing', (
      tester,
    ) async {
      // Unbounded growth pushes the trailing action off a narrow screen, and the
      // row silently loses its only control.
      await pump(
        tester,
        const MxListTile(
          title: long,
          subtitle: long,
          trailing: Icon(Icons.chevron_right),
        ),
        surface: const Size(320, 568),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('MxListTile interaction states', () {
    /// The ring the row draws while focused, read off the foreground decoration
    /// it is painted into. `null` means no ring — the resting shape.
    BorderSide? ringOf(WidgetTester tester) {
      final decorated = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MxListTile),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final border = (decorated.decoration as BoxDecoration).border;

      return border == null ? null : (border as Border).top;
    }

    Future<void> tabTo(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }

    for (final mode in <(String, bool)>[('light', false), ('dark', true)]) {
      final label = mode.$1;
      final isDark = mode.$2;

      testWidgets('$label · hover paints the row wash, exit clears it', (
        tester,
      ) async {
        // `ListTileThemeData` has no slot for hover, so before this the row took
        // `ThemeData.hoverColor` — a hardcoded black wash, the same value in
        // both modes, with no seed in it.
        await pump(
          tester,
          MxListTile(title: 'Academic Word List', onTap: () {}),
          isDark: isDark,
        );
        final theme = isDark ? buildDarkTheme() : buildLightTheme();
        final wash = AppInteractionStates.rowOverlay(
          theme.colorScheme,
        ).resolve(const <WidgetState>{WidgetState.hovered})!;

        final gesture = await hover(tester, find.byType(MxListTile));
        expectInkColor(tester, wash, reason: '$label: hover paints nothing');

        await gesture.moveTo(
          tester.getBottomRight(find.byType(MxListTile)) + const Offset(0, 40),
        );
        await tester.pumpAndSettle();

        expectNoInkColor(
          tester,
          wash,
          reason: '$label: the row kept its hover after the pointer left',
        );
      });

      testWidgets('$label · keyboard focus draws a ring, not only a tint', (
        tester,
      ) async {
        // A 10% wash measures around 1.15:1 against the surface behind it, and
        // WCAG 1.4.11 asks 3:1 of a focus indicator — a tint alone marks the
        // focused row for people who can already see where they are.
        await pump(
          tester,
          MxListTile(title: 'Academic Word List', onTap: () {}),
          isDark: isDark,
        );
        final atRest = tester.getRect(find.byType(MxListTile));
        expect(ringOf(tester), isNull);

        await tabTo(tester);

        expect(ringOf(tester)?.width, AppStroke.focus, reason: label);
        expect(
          tester.getRect(find.byType(MxListTile)),
          atRest,
          reason: '$label: the ring changed the row geometry',
        );
      });
    }

    testWidgets('selected and hover stay two different statements', (
      tester,
    ) async {
      // Selection says "this is the current one" and survives the pointer
      // leaving; hover says "the pointer is here" and does not. A row where one
      // overwrote the other would lose the state the user is navigating by.
      await pump(
        tester,
        MxListTile(title: 'Academic Word List', isSelected: true, onTap: () {}),
      );
      final theme = buildLightTheme();
      final wash = AppInteractionStates.rowOverlay(
        theme.colorScheme,
      ).resolve(const <WidgetState>{WidgetState.hovered})!;

      final gesture = await hover(tester, find.byType(MxListTile));

      expect(tester.widget<ListTile>(find.byType(ListTile)).selected, isTrue);
      expectInkColor(tester, wash);

      await gesture.moveTo(
        tester.getBottomRight(find.byType(MxListTile)) + const Offset(0, 40),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<ListTile>(find.byType(ListTile)).selected,
        isTrue,
        reason: 'the pointer leaving deselected the row',
      );
    });

    testWidgets('a disabled row takes neither pointer nor keyboard', (
      tester,
    ) async {
      // Both paths, because they are separate: `enabled: false` drops the tap
      // gesture, and it also has to drop the row out of the focus order — a row
      // that can be tabbed to and then does nothing on Enter is a dead end the
      // keyboard user cannot see.
      var taps = 0;
      await pump(
        tester,
        MxListTile(
          title: 'Academic Word List',
          isEnabled: false,
          onTap: () => taps += 1,
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      await tabTo(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(taps, 0);
      expect(ringOf(tester), isNull, reason: 'a disabled row took focus');
    });
  });
}
