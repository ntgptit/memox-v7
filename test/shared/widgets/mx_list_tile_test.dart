import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
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

  group('MxListTile combined states', () {
    // The intersections #431 §24 found untested: the row's own source argues
    // for each of them (`mx_list_tile.dart:29-32` — the ring is drawn in the
    // foreground *because* `selectedTileColor` would cover a background one),
    // and nothing asserted them. `MxCard` has the twin at
    // `mx_card_interaction_test.dart`.
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

    for (final mode in <(String, bool)>[('light', false), ('dark', true)]) {
      final label = mode.$1;
      final isDark = mode.$2;
      final theme = isDark ? buildDarkTheme() : buildLightTheme();

      testWidgets('$label · selected + focused: the ring sits over the fill, '
          'and selection survives', (tester) async {
        await pump(
          tester,
          MxListTile(
            title: 'Academic Word List',
            isSelected: true,
            onTap: () {},
          ),
          isDark: isDark,
        );
        final atRest = tester.getRect(find.byType(MxListTile));

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        final tile = tester.widget<ListTile>(find.byType(ListTile));
        expect(
          tile.selected,
          isTrue,
          reason: '$label: focus dropped selection',
        );
        expect(ringOf(tester)?.width, AppStroke.focus, reason: label);
        expect(
          ringOf(tester)?.color,
          AppInteractionStates.focusIndicator(theme.colorScheme).color,
          reason: '$label: the ring is not the focus indicator',
        );
        expect(
          tester.getRect(find.byType(MxListTile)),
          atRest,
          reason: '$label: focus moved a selected row',
        );
      });

      testWidgets('$label · selected + pressed: the press wash paints and '
          'the row stays selected', (tester) async {
        await pump(
          tester,
          MxListTile(
            title: 'Academic Word List',
            isSelected: true,
            onTap: () {},
          ),
          isDark: isDark,
        );
        final pressWash = AppInteractionStates.rowOverlay(
          theme.colorScheme,
        ).resolve(const <WidgetState>{WidgetState.pressed})!;

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(MxListTile)),
        );
        // Two pumps, not one: a `Ticker` measures elapsed time from its first
        // tick, so a single `pump(250ms)` lands on the highlight's first frame
        // at alpha 0. The second is past the 200ms fade-in and before the
        // ripple settles.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expectInkColor(tester, pressWash, reason: '$label: no press wash');
        expect(
          tester.widget<ListTile>(find.byType(ListTile)).selected,
          isTrue,
          reason: '$label: the press dropped selection',
        );
        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('$label · disabled + selected: announced as both, and the '
          'label leaves the live accent', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(
          tester,
          MxListTile(
            title: 'Academic Word List',
            isSelected: true,
            isEnabled: false,
            onTap: () {},
          ),
          isDark: isDark,
        );

        expect(
          tester.getSemantics(find.byType(ListTile)),
          matchesSemantics(
            hasSelectedState: true,
            isSelected: true,
            // A selectable row is one of an exclusive group (M100.36 10E).
            isInMutuallyExclusiveGroup: true,
            // `isEnabled` is left at the matcher's default — false — which is
            // the assertion: the flag is present and it is off.
            hasEnabledState: true,
            label: 'Academic Word List',
          ),
          reason: label,
        );
        // Disabled falls through to `theme.disabledColor`, which is seeded to
        // `semantic.onDisabled` — never `selectedColor`. A greyed row that
        // kept the accent would read as the one live choice in a dead list.
        final title = tester.widget<AnimatedDefaultTextStyle>(
          find
              .ancestor(
                of: find.text('Academic Word List'),
                matching: find.byType(AnimatedDefaultTextStyle),
              )
              .first,
        );
        expect(
          title.style.color,
          isNot(theme.colorScheme.primary),
          reason: '$label: a disabled selected row still wears the accent',
        );
        handle.dispose();
      });
    }
  });

  group('MxListTile contract (M100.36)', () {
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

    testWidgets('an inert row is out of the focus order and draws no ring', (
      tester,
    ) async {
      // #431 P1-2: a null `onTap` used to leave the row Tab-reachable, ringed
      // and inert on Enter — an unavailable study mode was the live case.
      await pump(
        tester,
        const Column(
          children: <Widget>[
            MxListTile(title: 'Unavailable mode', subtitle: 'No cards due'),
            MxListTile(title: 'Available mode', subtitle: '12 cards'),
          ],
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final inert = tester.widget<ListTile>(find.byType(ListTile).at(0));
      expect(inert.onTap, isNull);
      expect(
        tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(MxListTile).at(0),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration,
        isA<BoxDecoration>().having((d) => d.border, 'border', isNull),
        reason: 'an inert row drew the focus ring',
      );
      // Nothing on screen is focusable, so Tab lands nowhere.
      expect(
        FocusManager.instance.primaryFocus?.context?.widget,
        isNot(isA<InkWell>()),
      );
    });

    testWidgets('an interactive row takes focus and rings; the ring waits '
        'for a keyboard', (tester) async {
      await pump(
        tester,
        MxListTile(title: 'Academic Word List', onTap: () {}),
        settle: false,
      );
      // Programmatic focus in touch mode: focused, no ring — a phone with no
      // keyboard asked for no affordance (M100.36 10C).
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      inkWell.focusNode?.requestFocus();
      final focus = Focus.of(tester.element(find.byType(ListTile)));
      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(ringOf(tester), isNull, reason: 'a touch-mode focus grew a ring');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(ringOf(tester)?.width, AppStroke.focus);
    });

    testWidgets('the subtitle keeps the secondary ink, selected or not', (
      tester,
    ) async {
      // #431 P1-1 / P2-14: the theme's `textColor` flattened the subtitle onto
      // the title ink, and selection recoloured it `primary` with the title.
      final theme = buildLightTheme();
      for (final selected in <bool?>[null, false, true]) {
        await pump(
          tester,
          MxListTile(
            title: 'Academic Word List',
            subtitle: '20 of 570 learned',
            isSelected: selected,
            onTap: () {},
          ),
        );
        final subtitle = tester.renderObject<RenderParagraph>(
          find.text('20 of 570 learned'),
        );
        expect(
          subtitle.text.style?.color,
          theme.colorScheme.onSurfaceVariant,
          reason: 'selected=$selected: the subtitle left onSurfaceVariant',
        );
        final title = tester.renderObject<RenderParagraph>(
          find.text('Academic Word List'),
        );
        expect(
          title.text.style?.color,
          selected == true
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
          reason: 'selected=$selected: title ink',
        );
        // Selection moves colour, never typography (M100.36 4L).
        expect(
          title.text.style?.fontWeight,
          theme.textTheme.bodyLarge?.fontWeight,
        );
      }
    });

    testWidgets('a disabled subtitle greys with the row', (tester) async {
      final theme = buildLightTheme();
      await pump(
        tester,
        MxListTile(
          title: 'Academic Word List',
          subtitle: '20 of 570 learned',
          isEnabled: false,
          onTap: () {},
        ),
      );
      final subtitle = tester.renderObject<RenderParagraph>(
        find.text('20 of 570 learned'),
      );
      expect(
        subtitle.text.style?.color,
        isNot(theme.colorScheme.onSurfaceVariant),
      );
      expect(subtitle.text.style?.color, theme.disabledColor);
    });

    testWidgets('selection is tri-state, and a pick is one of an exclusive '
        'group', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        Column(
          children: <Widget>[
            MxListTile(title: 'Settings', onTap: () {}),
            MxListTile(title: 'Front → back', isSelected: true, onTap: () {}),
            MxListTile(title: 'Back → front', isSelected: false, onTap: () {}),
          ],
        ),
      );

      SemanticsNode nodeOf(String label) => tester.getSemantics(
        find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
      );

      expect(
        nodeOf('Settings'),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          // The SDK's flag, not the row's claim — `ListTile` 3.44.8 passes a
          // non-nullable `selected` (`list_tile.dart:997`).
          hasSelectedState: true,
          label: 'Settings',
        ),
      );
      final picked = nodeOf('Front → back').flagsCollection;
      final unpicked = nodeOf('Back → front').flagsCollection;
      final navigation = nodeOf('Settings').flagsCollection;
      expect(picked.isSelected, Tristate.isTrue);
      expect(unpicked.isSelected, Tristate.isFalse);
      // Exclusivity is stated where selection is a concept, and only there.
      expect(picked.isInMutuallyExclusiveGroup, isTrue);
      expect(unpicked.isInMutuallyExclusiveGroup, isTrue);
      expect(navigation.isInMutuallyExclusiveGroup, isFalse);
      handle.dispose();
    });

    testWidgets('a selected row fills with the shared picked surface', (
      tester,
    ) async {
      await pump(
        tester,
        MxListTile(title: 'Front → back', isSelected: true, onTap: () {}),
      );
      final theme = buildLightTheme();
      final semantic = theme.extension<AppSemanticColors>()!;
      final ink = tester.widget<Ink>(
        find.descendant(of: find.byType(ListTile), matching: find.byType(Ink)),
      );
      expect(
        (ink.decoration! as ShapeDecoration).color,
        semantic.surfaceSelected,
        reason: 'the row and the card no longer share one picked fill',
      );
    });

    testWidgets('owns its Material, so it paints inside a decorated card', (
      tester,
    ) async {
      // #431 P2-11: two callers hand-wrote `Material(transparency)` around
      // the row so its ink and fill were not painted behind the card.
      await pump(
        tester,
        DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF888888)),
          child: MxListTile(title: 'Reminders', onTap: () {}),
        ),
      );
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(MxListTile),
          matching: find.byType(Material),
        ),
      );
      expect(material.type, MaterialType.transparency);
    });

    testWidgets('a trailing text is set at a readable rung', (tester) async {
      // #431 P2-8: `_LisTileDefaultsM3.leadingAndTrailingTextStyle` is
      // label-sm at 11px, below anything this app reads.
      await pump(
        tester,
        MxListTile(
          title: 'Reminder time',
          trailing: const Text('08:00'),
          onTap: () {},
        ),
      );
      final theme = buildLightTheme();
      final trailing = tester.renderObject<RenderParagraph>(find.text('08:00'));
      expect(
        trailing.text.style?.fontSize,
        theme.textTheme.bodyMedium?.fontSize,
      );
      expect(trailing.text.style?.color, theme.colorScheme.onSurfaceVariant);
    });
  });
}
