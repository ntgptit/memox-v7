import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

/// `MxChipTrigger` — the ghost menu trigger. Never selectable, never owns the
/// menu it opens: see the widget's own doc comment for why it is not a
/// variant of `MxPillButton`.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget trigger, {
    bool isDark = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: Scaffold(body: Center(child: trigger)),
      ),
    );
    // `MaterialApp` lerps theme changes through `AnimatedTheme` over
    // `kThemeAnimationDuration`; a single `pumpWidget` frame still paints the
    // *previous* theme mid-animation. Settling here is what lets the
    // light/dark toggle in the `theming` group actually observe the theme it
    // just switched to, instead of the one it switched from.
    await tester.pumpAndSettle();
  }

  // The one foreground `DecoratedBox` is `MxFocusRing`'s: it exists whether or
  // not it is focused, and sizes to whatever it wraps.
  final Finder ringFinder = find.byWidgetPredicate(
    (Widget w) =>
        w is DecoratedBox && w.position == DecorationPosition.foreground,
  );

  group('interaction', () {
    testWidgets('reports a press', (tester) async {
      var presses = 0;
      await pump(
        tester,
        MxChipTrigger(label: 'Newest first', onPressed: () => presses += 1),
      );

      await tester.tap(find.byType(MxChipTrigger));
      await tester.pump();

      expect(presses, 1);
    });

    testWidgets('a null callback disables it', (tester) async {
      await pump(
        tester,
        const MxChipTrigger(label: 'Newest first', onPressed: null),
      );

      final semantics = tester.getSemantics(find.byType(MxChipTrigger));
      expect(
        semantics,
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          label: 'Newest first',
        ),
      );
    });
  });

  group('semantics', () {
    testWidgets('announces as a button, never as selected', (tester) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxChipTrigger(label: 'Newest first', onPressed: () {}),
      );

      expect(
        tester.getSemantics(find.byType(MxChipTrigger)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          label: 'Newest first',
        ),
      );
      handle.dispose();
    });

    testWidgets('an override replaces the visible label, not appends it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxChipTrigger(
          label: 'A-Z',
          semanticLabel: 'Sorted by name. Activate to change the sort order.',
          onPressed: () {},
        ),
      );

      expect(
        find.bySemanticsLabel(
          'Sorted by name. Activate to change the sort order.',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('A-Z'), findsNothing);
      handle.dispose();
    });
  });

  group('layout', () {
    testWidgets('meets the 48 touch target on both axes', (tester) async {
      await pump(tester, MxChipTrigger(label: 'X', onPressed: () {}));

      final size = tester.getSize(find.byType(MxChipTrigger));
      expect(size.height, greaterThanOrEqualTo(AppSizing.touchTarget));
      expect(size.width, greaterThanOrEqualTo(AppSizing.touchTarget));
    });

    testWidgets('the painted content band is exactly 28', (tester) async {
      await pump(
        tester,
        MxChipTrigger(label: 'Newest first', onPressed: () {}),
      );

      expect(tester.getSize(find.byType(Row)).height, 28);
    });

    testWidgets('the trailing chevron is always painted, at 16', (
      tester,
    ) async {
      await pump(
        tester,
        MxChipTrigger(label: 'Newest first', onPressed: () {}),
      );

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      final Size icon = tester.getSize(find.byIcon(Icons.expand_more));
      expect(icon.width, 16);
      expect(icon.height, 16);
    });

    testWidgets('a leading icon paints only when supplied', (tester) async {
      await pump(tester, MxChipTrigger(label: 'Manual', onPressed: () {}));
      expect(find.byIcon(Icons.tune), findsNothing);

      await pump(
        tester,
        MxChipTrigger(
          label: 'Manual',
          leadingIcon: Icons.tune,
          onPressed: () {},
        ),
      );
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('a long label lengthens the trigger instead of clipping it', (
      tester,
    ) async {
      const longLabel =
          'A label long enough that a fixed-width chip would have to '
          'ellipsize it';

      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 100,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: MxChipTrigger(label: longLabel, onPressed: () {}),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MxChipTrigger)).width,
        greaterThan(100),
      );
      expect(find.text(longLabel), findsOneWidget);
    });
  });

  group('touch target', () {
    // The 48 box has to be a *hit* area, not only a layout one: a bare
    // `ConstrainedBox` + `Center` sizes the box and leaves the padding inert.
    testWidgets('a press in the vertical padding fires', (tester) async {
      var presses = 0;
      await pump(
        tester,
        MxChipTrigger(label: 'Newest first', onPressed: () => presses += 1),
      );

      final Rect target = tester.getRect(find.byType(MxChipTrigger));
      final Rect band = tester.getRect(ringFinder);
      expect(band.top - target.top, greaterThan(8), reason: 'no padding');

      await tester.tapAt(Offset(target.center.dx, target.center.dy - 22));
      await tester.tapAt(Offset(target.center.dx, target.center.dy + 22));

      expect(presses, 2);
    });

    testWidgets('a press in the horizontal padding fires', (tester) async {
      var presses = 0;
      await pump(
        tester,
        MxChipTrigger(label: 'X', onPressed: () => presses += 1),
      );

      final Rect target = tester.getRect(find.byType(MxChipTrigger));
      final Rect band = tester.getRect(ringFinder);
      expect(band.left - target.left, greaterThan(0.5), reason: 'no padding');

      await tester.tapAt(Offset(target.left + 0.5, target.center.dy));
      await tester.tapAt(Offset(target.right - 0.5, target.center.dy));

      expect(presses, 2);
    });

    testWidgets('a disabled trigger ignores the padding too', (tester) async {
      await pump(
        tester,
        const MxChipTrigger(label: 'Newest first', onPressed: null),
      );

      final Rect target = tester.getRect(find.byType(MxChipTrigger));

      await tester.tapAt(Offset(target.center.dx, target.center.dy - 22));

      expect(tester.takeException(), isNull);
    });
  });

  group('theming', () {
    // The label and both glyphs wear one ink: `quiet` (`onSurfaceVariant`)
    // enabled, `disabled` (`AppSemanticColors.onDisabled`) when `onPressed` is
    // null — read off the painted `Text` and `Icon`s, not the theme.
    Color labelInk(WidgetTester tester) =>
        tester.widget<Text>(find.text('Newest first')).style!.color!;
    Color glyphInk(WidgetTester tester, IconData icon) =>
        tester.widget<Icon>(find.byIcon(icon)).color!;

    testWidgets('label and both glyphs are onSurfaceVariant when enabled', (
      tester,
    ) async {
      for (final isDark in <bool>[false, true]) {
        await pump(
          tester,
          MxChipTrigger(
            label: 'Newest first',
            leadingIcon: Icons.swap_vert,
            onPressed: () {},
          ),
          isDark: isDark,
        );

        final ink = (isDark ? buildDarkTheme() : buildLightTheme())
            .colorScheme
            .onSurfaceVariant;
        expect(labelInk(tester), ink, reason: 'label, dark: $isDark');
        expect(glyphInk(tester, Icons.swap_vert), ink, reason: 'leading');
        expect(glyphInk(tester, Icons.expand_more), ink, reason: 'chevron');
      }
    });

    testWidgets('label and both glyphs are onDisabled when disabled', (
      tester,
    ) async {
      for (final isDark in <bool>[false, true]) {
        await pump(
          tester,
          const MxChipTrigger(
            label: 'Newest first',
            leadingIcon: Icons.swap_vert,
            onPressed: null,
          ),
          isDark: isDark,
        );

        final ThemeData theme = isDark ? buildDarkTheme() : buildLightTheme();
        final Color ink = theme.extension<AppSemanticColors>()!.onDisabled;
        expect(labelInk(tester), ink, reason: 'label, dark: $isDark');
        expect(glyphInk(tester, Icons.swap_vert), ink, reason: 'leading');
        expect(glyphInk(tester, Icons.expand_more), ink, reason: 'chevron');
        expect(
          ink,
          isNot(theme.colorScheme.onSurfaceVariant),
          reason: 'disabled is indistinguishable from enabled',
        );
      }
    });
  });

  group('focus', () {
    BoxDecoration? ringDecoration(WidgetTester tester) {
      final Finder finder = find.byWidgetPredicate(
        (Widget w) =>
            w is DecoratedBox && w.position == DecorationPosition.foreground,
      );
      if (finder.evaluate().isEmpty) return null;

      return tester.widget<DecoratedBox>(finder.first).decoration
          as BoxDecoration?;
    }

    testWidgets('draws no ring until focused, then the primary ring', (
      tester,
    ) async {
      await pump(
        tester,
        MxChipTrigger(label: 'Newest first', onPressed: () {}),
      );
      expect(ringDecoration(tester)?.border, isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final BoxDecoration? decoration = ringDecoration(tester);
      expect(decoration?.border, isNotNull);
      expect(
        decoration!.border!.top.color,
        AppInteractionStates.focusIndicator(
          buildLightTheme().colorScheme,
        ).color,
      );
    });

    testWidgets('the ring traces the 28dp band, not the 48 touch target', (
      tester,
    ) async {
      await pump(
        tester,
        MxChipTrigger(label: 'Newest first', onPressed: () {}),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(ringFinder, findsOneWidget);
      final Rect ring = tester.getRect(ringFinder);
      final Rect target = tester.getRect(find.byType(MxChipTrigger));

      expect(ring.height, 28);
      expect(target.height, greaterThan(ring.height));
    });
  });
}
