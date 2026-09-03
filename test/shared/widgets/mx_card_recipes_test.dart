import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// The recipe table of `MxCard`, pinned value by value.
///
/// Each named constructor maps one-to-one onto a private spec — fill, edge,
/// radius, depth, padding. The API exposes none of those as parameters any
/// more, so this file is where the mapping is observable: a recipe that
/// silently changed its fill or its corner fails here, not on a golden three
/// screens away.
void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
    'high-contrast light': buildHighContrastLightTheme(),
    'high-contrast dark': buildHighContrastDarkTheme(),
  };

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    required ThemeData theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: Center(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  BoxDecoration decorationOf(WidgetTester tester) {
    final decorated = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MxCard),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );

    return decorated.decoration as BoxDecoration;
  }

  double radiusOf(BoxDecoration decoration) =>
      (decoration.borderRadius! as BorderRadius).topLeft.x;

  /// The colour of the edge the card paints over its child, or `null` for none.
  ///
  /// **The edge moved to a foreground layer at M100.33**, so it is no longer on
  /// the decoration [decorationOf] returns — that one is the fill. A card with
  /// nothing to show paints no border at all now; it used to draw one in its
  /// own fill, on the belief that `BoxDecoration.border` insets the child.
  /// `Container` does that. `DecoratedBox` does not, and this card has always
  /// been a `DecoratedBox`, so the invisible line reserved nothing.
  Color? edgeColorOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(MxCard),
          matching: find.byType(DecoratedBox),
        ),
      )
      .where(
        (DecoratedBox box) => box.position == DecorationPosition.foreground,
      )
      .map((DecoratedBox box) => (box.decoration as BoxDecoration).border)
      .whereType<Border>()
      .map((Border border) => border.top.color)
      .firstOrNull;

  Color borderColorOf(WidgetTester tester) => edgeColorOf(tester)!;

  bool hasVisibleBorder(WidgetTester tester) => edgeColorOf(tester) != null;

  bool hasShadow(BoxDecoration decoration) =>
      decoration.boxShadow != null && decoration.boxShadow!.isNotEmpty;

  group('recipe specs hold in every theme', () {
    for (final entry in themes.entries) {
      final themeName = entry.key;
      final theme = entry.value;
      final scheme = theme.colorScheme;
      final semantic = theme.extension<AppSemanticColors>()!;
      final isDark = scheme.brightness == Brightness.dark;

      testWidgets('$themeName · flat: surface, no edge, lg, no shadow', (
        tester,
      ) async {
        await pump(tester, const MxCard.flat(child: Text('x')), theme: theme);

        final decoration = decorationOf(tester);
        expect(decoration.color, scheme.surfaceContainerLow);
        // **No edge, and that is M99.94.** Every card used to wear a
        // `borderSubtle` hairline — 1.45:1 on its own fill in light — so a
        // screen of cards read as a stack of frames. The reference concept
        // draws none: its cards are pure white on a tinted page, and the
        // boundary is a colour edge rather than a drawn line.
        expect(hasVisibleBorder(tester), isFalse);
        expect(radiusOf(decoration), AppRadius.lg);
        expect(hasShadow(decoration), isFalse);
      });

      testWidgets(
        '$themeName · raised: surface, lg, shadow in light, surfaceContainer in dark',
        (tester) async {
          await pump(
            tester,
            const MxCard.raised(child: Text('x')),
            theme: theme,
          );

          final decoration = decorationOf(tester);
          // **One role in both modes since M100.33.** Dark used to resolve
          // this recipe to `surfaceContainer` and light to
          // `surfaceContainerLow`, so `MxCard.raised` had two semantic
          // identities and which one you got depended on the theme. Dark still
          // needs the step — it paints no shadow — but it takes it from the rim
          // thickening with the level, which is paint rather than meaning.
          expect(decoration.color, scheme.surfaceContainerLow);
          expect(hasVisibleBorder(tester), isFalse);
          expect(radiusOf(decoration), AppRadius.lg);
          // Since M100.27 dark paints Tokyo's rim, so every lifted recipe
          // carries a BoxShadow in both modes.
          expect(hasShadow(decoration), isTrue);
        },
      );

      testWidgets('$themeName · focal: xl corner, lifted in every theme', (
        tester,
      ) async {
        await pump(tester, const MxCard.focal(child: Text('x')), theme: theme);

        final decoration = decorationOf(tester);
        // Same role as `raised`, in both modes; the depth between them is
        // carried by the shadow in light and by the rim's width in dark.
        expect(decoration.color, scheme.surfaceContainerLow);
        expect(radiusOf(decoration), AppRadius.xl);
        expect(hasShadow(decoration), isTrue);
      });

      testWidgets('$themeName · recessed: one step down, xl, flat', (
        tester,
      ) async {
        await pump(
          tester,
          const MxCard.recessed(child: Text('x')),
          theme: theme,
        );

        final decoration = decorationOf(tester);
        // One rung *below* the paper. It read `surfaceContainerLow` until
        // M100.32; that rung is the paper now, so the recess moved down to
        // `surfaceContainerLowest` and renders the colour it always did.
        expect(decoration.color, scheme.surfaceContainerLowest);
        // At rest it draws no edge either; the edge is what its *states* use,
        // asserted by the case below.
        expect(hasVisibleBorder(tester), isFalse);
        expect(radiusOf(decoration), AppRadius.xl);
        expect(hasShadow(decoration), isFalse);
      });

      testWidgets('$themeName · recessed edges map to their tokens', (
        tester,
      ) async {
        final expectations = <MxCardRecessedEdge, Color>{
          MxCardRecessedEdge.focus: scheme.primary,
          MxCardRecessedEdge.success: semantic.success,
          MxCardRecessedEdge.danger: semantic.danger,
        };
        for (final edge in expectations.entries) {
          await pump(
            tester,
            MxCard.recessed(edge: edge.key, child: const Text('x')),
            theme: theme,
          );
          expect(
            borderColorOf(tester),
            edge.value,
            reason: '$themeName: ${edge.key} lost its token',
          );
        }
      });

      testWidgets('$themeName · feedback danger: errorContainer, flat', (
        tester,
      ) async {
        await pump(
          tester,
          const MxCard.feedback(
            tone: MxCardFeedbackTone.danger,
            child: Text('x'),
          ),
          theme: theme,
        );

        final decoration = decorationOf(tester);
        expect(decoration.color, scheme.errorContainer);
        expect(hasShadow(decoration), isFalse);
        expect(radiusOf(decoration), AppRadius.lg);
      });

      testWidgets('$themeName · muted: surfaceContainerHigh aside', (
        tester,
      ) async {
        await pump(tester, const MxCard.muted(child: Text('x')), theme: theme);

        final decoration = decorationOf(tester);
        expect(decoration.color, scheme.surfaceContainerHigh);
        expect(radiusOf(decoration), AppRadius.lg);
        // **Flat, and it carried card-level depth until M99.95.** The fill sits
        // 3.16 L* *below* the page, so a shadow under it had the card claiming
        // "lifted" and "sunken" at once — visible on `card_import_source_light`
        // where the note band cast a shadow the content panel it annotates did
        // not. Pinned in the new direction so the one recipe whose tone already
        // states its depth cannot quietly grow a second claim.
        expect(hasShadow(decoration), isFalse);
      });

      testWidgets('$themeName · tonal: the emphasis surface, flat', (
        tester,
      ) async {
        await pump(tester, const MxCard.tonal(child: Text('x')), theme: theme);

        final decoration = decorationOf(tester);
        // **`surfaceEmphasis`, and it used to be `secondaryContainer`**
        // (M99.98). That token is chroma 0.0084 in light — effectively neutral
        // — and sat 5.24 L* below the page, so Study Home's resume callout, the
        // screen's primary action, was the greyest thing on it. The new value
        // is 1.11 below the page with 3.6x its chroma: marked by hue, not by
        // weight.
        expect(decoration.color, semantic.surfaceEmphasis);
        // **Light only.** The reference concept is light-only, and in dark
        // `#332F58` already carries a real violet and reads as a callout, so
        // `surfaceEmphasisDark` deliberately keeps the value it had — see
        // `AppSurfaceColors.surfaceEmphasisDark`. Asserting the divergence where it
        // exists, rather than forcing dark to move without a reference to
        // measure it against.
        if (!isDark) {
          expect(decoration.color, isNot(scheme.secondaryContainer));
        }
        expect(hasShadow(decoration), isFalse);
      });

      testWidgets('$themeName · accent: borderAccent, lifted in every theme', (
        tester,
      ) async {
        await pump(tester, const MxCard.accent(child: Text('x')), theme: theme);

        final decoration = decorationOf(tester);
        // The same role as `raised`/`focal`; `accent` is told apart by its
        // edge, and its depth by the same shadow-or-rim the others use.
        expect(decoration.color, scheme.surfaceContainerLow);
        expect(borderColorOf(tester), semantic.borderAccent);
        expect(hasShadow(decoration), isTrue);
      });

      testWidgets('$themeName · tile: control corner, lifted like any '
          'page card', (tester) async {
        await pump(tester, const MxCard.tile(child: Text('x')), theme: theme);

        final decoration = decorationOf(tester);
        // One role in both modes, as for `.raised`: dark says "above the
        // page" with the rim it paints, not by moving to another fill.
        expect(decoration.color, scheme.surfaceContainerLow);
        expect(radiusOf(decoration), AppRadius.md);
        // **It was `flat`, and that stopped being survivable when the hairline
        // went** (M99.94). A tile is a card on a page — the study-history
        // timeline is the caller — so with no line *and* no shadow it had
        // 2.15 L* of fill and nothing else. It now carries the same level-1
        // lift every other page card takes; only the corner still separates it
        // from `.raised`, which is what the recipe was ever about.
        expect(hasShadow(decoration), isTrue);
      });

      testWidgets('$themeName · option: its own brand edge, flat', (
        tester,
      ) async {
        await pump(
          tester,
          MxCard.option(
            isSelected: false,
            onTap: () {},
            child: const Text('x'),
          ),
          theme: theme,
        );

        final decoration = decorationOf(tester);
        expect(decoration.color, scheme.surfaceContainerLow);
        // **`borderOption`, not `borderControl`** (M100.2). An option card had
        // been borrowing the *input* border, which `app_palette_test.dart`
        // keeps untinted by a recorded rule — "the light canvas carries no
        // lavender tint" names `input` explicitly. That rule is about a text
        // field, which is canvas; a card sitting on a page is not, and its
        // neighbours' edges moved into the brand family at M99.99.
        expect(borderColorOf(tester), semantic.borderOption);
        expect(borderColorOf(tester), isNot(semantic.borderControl));
        expect(hasShadow(decoration), isFalse);
      });
    }
  });

  group('padding is a closed scale', () {
    final expectations = <MxCardPadding, double>{
      MxCardPadding.none: 0,
      MxCardPadding.compact: AppSpacing.md,
      MxCardPadding.standard: AppSpacing.lg,
    };

    for (final step in expectations.entries) {
      testWidgets('${step.key} maps to ${step.value}', (tester) async {
        // The content's offset from the card's own corner is the padding —
        // a `DecoratedBox` never insets its child for the border, so the
        // measurement is direct.
        await pump(
          tester,
          MxCard.flat(padding: step.key, child: const Text('x')),
          theme: buildLightTheme(),
        );

        final card = tester.getTopLeft(find.byType(MxCard));
        final content = tester.getTopLeft(find.text('x'));
        expect(content.dx - card.dx, step.value);
        expect(content.dy - card.dy, step.value);
      });
    }

    testWidgets('feedback and tile own the compact step', (tester) async {
      // Density that is part of a recipe's meaning is fixed by it, not
      // exposed: six error bands and the history tile all shipped `md` by
      // hand before the recipe owned it.
      await pump(
        tester,
        const MxCard.feedback(
          tone: MxCardFeedbackTone.danger,
          child: Text('x'),
        ),
        theme: buildLightTheme(),
      );
      var card = tester.getTopLeft(find.byType(MxCard));
      var content = tester.getTopLeft(find.text('x'));
      expect(content.dx - card.dx, AppSpacing.md);

      await pump(
        tester,
        const MxCard.tile(child: Text('x')),
        theme: buildLightTheme(),
      );
      card = tester.getTopLeft(find.byType(MxCard));
      content = tester.getTopLeft(find.text('x'));
      expect(content.dx - card.dx, AppSpacing.md);
    });
  });

  group('selection treatments', () {
    testWidgets('the edge treatment leaves the fill alone', (tester) async {
      final theme = buildLightTheme();
      await pump(
        tester,
        MxCard.flat(isSelected: true, onTap: () {}, child: const Text('x')),
        theme: theme,
      );

      final decoration = decorationOf(tester);
      expect(decoration.color, theme.colorScheme.surfaceContainerLow);
      // **`borderSelected`, not `secondary`** (M99.99). The slate edge carried
      // chroma 0.0337 — a fifth of the brand family — around a fill M99.98 had
      // just made brand-tinted, so the card said two different things about one
      // state. The measurement that once ruled brand out was taken against
      // `surface`; this edge sits on `surfaceSelected`, where it clears 3:1.
      expect(
        borderColorOf(tester),
        theme.extension<AppSemanticColors>()!.borderSelected,
      );
    });

    testWidgets('the tint treatment adds the fill when — and only when — '
        'selected', (tester) async {
      final theme = buildLightTheme();
      await pump(
        tester,
        MxCard.flat(
          isSelected: true,
          selectionTreatment: MxCardSelectionTreatment.tint,
          onTap: () {},
          child: const Text('x'),
        ),
        theme: theme,
      );
      // Selecting something must not dim it: the tint is the brand-tinted
      // `surfaceSelected`, *lighter* than the grey it replaced, so a picked row
      // no longer renders darker than the unpicked ones beside it (M99.98).
      expect(
        decorationOf(tester).color,
        theme.extension<AppSemanticColors>()!.surfaceSelected,
      );

      await pump(
        tester,
        MxCard.flat(
          isSelected: false,
          selectionTreatment: MxCardSelectionTreatment.tint,
          onTap: () {},
          child: const Text('x'),
        ),
        theme: theme,
      );
      expect(decorationOf(tester).color, theme.colorScheme.surfaceContainerLow);
    });
  });
}
