import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_radius.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_spacing.dart';
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

  Color borderColorOf(BoxDecoration decoration) =>
      (decoration.border! as Border).top.color;

  bool hasShadow(BoxDecoration decoration) =>
      decoration.boxShadow != null && decoration.boxShadow!.isNotEmpty;

  group('recipe specs hold in every theme', () {
    for (final entry in themes.entries) {
      final themeName = entry.key;
      final theme = entry.value;
      final scheme = theme.colorScheme;
      final semantic = theme.extension<AppSemanticColors>()!;
      final isDark = scheme.brightness == Brightness.dark;

      testWidgets('$themeName · flat: surface, hairline, lg, no shadow', (
        tester,
      ) async {
        await pump(tester, const MxCard.flat(child: Text('x')), theme: theme);

        final decoration = decorationOf(tester);
        expect(decoration.color, scheme.surface);
        expect(borderColorOf(decoration), semantic.borderSubtle);
        expect(radiusOf(decoration), AppRadius.lg);
        expect(hasShadow(decoration), isFalse);
      });

      testWidgets('$themeName · raised: surface, lg, shadow in light only', (
        tester,
      ) async {
        await pump(tester, const MxCard.raised(child: Text('x')), theme: theme);

        final decoration = decorationOf(tester);
        expect(decoration.color, scheme.surface);
        expect(borderColorOf(decoration), semantic.borderSubtle);
        expect(radiusOf(decoration), AppRadius.lg);
        // AD-14: dark builds its depth from the surface step and draws no
        // shadow; light carries the difference as paint.
        expect(hasShadow(decoration), !isDark);
      });

      testWidgets('$themeName · focal: xl corner, lifted in light', (
        tester,
      ) async {
        await pump(tester, const MxCard.focal(child: Text('x')), theme: theme);

        final decoration = decorationOf(tester);
        expect(decoration.color, scheme.surface);
        expect(radiusOf(decoration), AppRadius.xl);
        expect(hasShadow(decoration), !isDark);
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
        expect(decoration.color, scheme.surfaceContainerLow);
        expect(borderColorOf(decoration), semantic.borderSubtle);
        expect(radiusOf(decoration), AppRadius.xl);
        expect(hasShadow(decoration), isFalse);
      });

      testWidgets('$themeName · recessed edges map to their tokens', (
        tester,
      ) async {
        final expectations = <MxCardRecessedEdge, Color>{
          MxCardRecessedEdge.focus: semantic.focusRing,
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
            borderColorOf(decorationOf(tester)),
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
        // Card-level depth, kept from the bare `MxCard` the info panels used
        // to build — pinned so the one recipe without a depth claim cannot
        // drift elevation with no test going red.
        expect(hasShadow(decoration), !isDark);
      });

      testWidgets('$themeName · tonal: secondaryContainer callout, flat', (
        tester,
      ) async {
        await pump(tester, const MxCard.tonal(child: Text('x')), theme: theme);

        final decoration = decorationOf(tester);
        expect(decoration.color, scheme.secondaryContainer);
        expect(hasShadow(decoration), isFalse);
      });

      testWidgets('$themeName · accent: borderAccent, lifted in light', (
        tester,
      ) async {
        await pump(tester, const MxCard.accent(child: Text('x')), theme: theme);

        final decoration = decorationOf(tester);
        expect(decoration.color, scheme.surface);
        expect(borderColorOf(decoration), semantic.borderAccent);
        expect(hasShadow(decoration), !isDark);
      });

      testWidgets('$themeName · tile: control corner, flat', (tester) async {
        await pump(tester, const MxCard.tile(child: Text('x')), theme: theme);

        final decoration = decorationOf(tester);
        expect(decoration.color, scheme.surface);
        expect(radiusOf(decoration), AppRadius.md);
        expect(hasShadow(decoration), isFalse);
      });

      testWidgets('$themeName · option: control edge, flat', (tester) async {
        await pump(
          tester,
          const MxCard.option(isSelected: false, child: Text('x')),
          theme: theme,
        );

        final decoration = decorationOf(tester);
        expect(decoration.color, scheme.surface);
        expect(borderColorOf(decoration), semantic.borderControl);
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
      expect(decoration.color, theme.colorScheme.surface);
      expect(borderColorOf(decoration), theme.colorScheme.secondary);
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
      expect(decorationOf(tester).color, theme.colorScheme.secondaryContainer);

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
      expect(decorationOf(tester).color, theme.colorScheme.surface);
    });
  });
}
