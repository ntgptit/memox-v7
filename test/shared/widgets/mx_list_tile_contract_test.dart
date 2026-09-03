import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';

/// `MxListTile`'s M100.36 contract — tri-state selection, exclusivity, the
/// inert row's focus, the subtitle's ink and the Material it owns.
///
/// Split from `mx_list_tile_test.dart` at the 400-line guard, on the seam the
/// groups already had: that file asserts the interaction and combined states
/// the row grew with the common contract; this one asserts what #431 changed.
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
