import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

void main() {
  group('MxIconTile', () {
    testWidgets('sizes the tile at 28x28', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: MxIconTile(icon: Icons.layers_outlined)),
        ),
      );

      expect(tester.getSize(find.byType(MxIconTile)), const Size(28, 28));
    });

    testWidgets(
      'default tone tints the fill and glyph with primary, light theme',
      (tester) async {
        final ThemeData theme = buildLightTheme();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(body: MxIconTile(icon: Icons.layers_outlined)),
          ),
        );

        final DecoratedBox box = tester.widget(find.byType(DecoratedBox));
        final BoxDecoration decoration = box.decoration as BoxDecoration;
        final Color expectedFill = Color.alphaBlend(
          theme.colorScheme.primary.withValues(alpha: 0.10),
          theme.colorScheme.surface,
        );
        expect(decoration.color, expectedFill);

        final Icon icon = tester.widget(find.byType(Icon));
        expect(icon.color, theme.colorScheme.primary);
      },
    );

    testWidgets('default tone tints at 16% in dark theme', (tester) async {
      final ThemeData theme = buildDarkTheme();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: MxIconTile(icon: Icons.layers_outlined)),
        ),
      );

      final DecoratedBox box = tester.widget(find.byType(DecoratedBox));
      final BoxDecoration decoration = box.decoration as BoxDecoration;
      final Color expectedFill = Color.alphaBlend(
        theme.colorScheme.primary.withValues(alpha: 0.16),
        theme.colorScheme.surface,
      );
      expect(decoration.color, expectedFill);
    });

    testWidgets('seeded tone tints the fill and glyph with the seed colour', (
      tester,
    ) async {
      const Color seed = Color(0xFF5265F5);
      final ThemeData theme = buildLightTheme();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: MxIconTile(icon: Icons.layers_outlined, seed: seed),
          ),
        ),
      );

      final DecoratedBox box = tester.widget(find.byType(DecoratedBox));
      final BoxDecoration decoration = box.decoration as BoxDecoration;
      final Color expectedFill = Color.alphaBlend(
        seed.withValues(alpha: 0.12),
        theme.colorScheme.surface,
      );
      expect(decoration.color, expectedFill);

      final Icon icon = tester.widget(find.byType(Icon));
      expect(icon.color, seed);
    });

    testWidgets('null semanticLabel excludes the glyph from semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: MxIconTile(icon: Icons.layers_outlined)),
        ),
      );

      // An ancestor check, not a bare byType count: Icon itself always wraps
      // its own glyph in an internal ExcludeSemantics regardless of
      // semanticLabel (a descendant of Icon, on this Flutter), and
      // MaterialApp/Scaffold contribute an unrelated ExcludeSemantics of
      // their own elsewhere in the tree (edge-drag gesture region). What
      // MxIconTile itself decides is whether it wraps the Icon widget in an
      // ExcludeSemantics of its own — i.e. whether one is an ancestor of it.
      expect(
        find.ancestor(
          of: find.byType(Icon),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      final Icon icon = tester.widget(find.byType(Icon));
      expect(icon.semanticLabel, isNull);
    });

    testWidgets('a semanticLabel is forwarded to the glyph, not excluded', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(
            body: MxIconTile(
              icon: Icons.layers_outlined,
              semanticLabel: 'Vocabulary deck',
            ),
          ),
        ),
      );

      // MxIconTile adds no ExcludeSemantics of its own here — see the
      // ancestor-vs-byType note on the null-label test above.
      expect(
        find.ancestor(
          of: find.byType(Icon),
          matching: find.byType(ExcludeSemantics),
        ),
        findsNothing,
      );
      final Icon icon = tester.widget(find.byType(Icon));
      expect(icon.semanticLabel, 'Vocabulary deck');
    });
  });
}
