import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/extensions/app_ink.dart';
import 'package:memox/core/theme/schemes/app_color_scheme.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

/// M-xx — the contract `MxIconTile` exists for: a fixed geometry per size
/// step, a computed tint (default `primary` or a caller `seed`) rather than
/// a theme role, and the icon/child slot is mutually exclusive.
void main() {
  Future<void> pump(WidgetTester tester, Widget child, {ThemeData? theme}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: theme ?? buildLightTheme(),
          home: Scaffold(body: child),
        ),
      );

  for (final step in MxIconTileSize.values) {
    testWidgets('dimensions for ${step.name}', (tester) async {
      await pump(tester, MxIconTile(icon: Icons.folder, size: step));

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(DecoratedBox),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, step.box);
      expect(sizedBox.height, step.box);

      final decoratedBox = tester.widget<DecoratedBox>(
        find.byType(DecoratedBox),
      );
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(step.radius));

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, step.glyphSize);
    });
  }

  testWidgets('default tint under light theme: primary at 10% on surface', (
    tester,
  ) async {
    await pump(tester, const MxIconTile(icon: Icons.folder));

    final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;
    expect(
      decoration.color,
      Color.alphaBlend(
        lightColorScheme.primary.withValues(alpha: 0.10),
        lightColorScheme.surface,
      ),
    );

    final context = tester.element(find.byType(Icon));
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, lightColorScheme.primary);
    // The glyph is bound to ColorScheme.primary directly, never AppInk.accent
    // — assert the two differ in this theme so this cannot pass by accident.
    expect(icon.color, isNot(AppInk.accent.resolve(context)));
  });

  testWidgets('default tint under dark theme: primary at 16% on surface', (
    tester,
  ) async {
    await pump(
      tester,
      const MxIconTile(icon: Icons.folder),
      theme: buildDarkTheme(),
    );

    final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;
    expect(
      decoration.color,
      Color.alphaBlend(
        darkColorScheme.primary.withValues(alpha: 0.16),
        darkColorScheme.surface,
      ),
    );

    final context = tester.element(find.byType(Icon));
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, darkColorScheme.primary);
    expect(icon.color, isNot(AppInk.accent.resolve(context)));
  });

  testWidgets('seeded tint under light theme: flat 12% on surface', (
    tester,
  ) async {
    const seed = Color(0xFF2E7D32); // arbitrary, documented as a probe value
    await pump(tester, const MxIconTile(icon: Icons.folder, seed: seed));

    final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;
    expect(
      decoration.color,
      Color.alphaBlend(seed.withValues(alpha: 0.12), lightColorScheme.surface),
    );

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, seed);
  });

  testWidgets('seeded tint under dark theme: flat 12% on surface', (
    tester,
  ) async {
    const seed = Color(0xFF2E7D32); // arbitrary, documented as a probe value
    await pump(
      tester,
      const MxIconTile(icon: Icons.folder, seed: seed),
      theme: buildDarkTheme(),
    );

    final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;
    expect(
      decoration.color,
      Color.alphaBlend(seed.withValues(alpha: 0.12), darkColorScheme.surface),
    );

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, seed);
  });

  testWidgets('a null label excludes the glyph from semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const MxIconTile(icon: Icons.star));

    expect(
      find.ancestor(
        of: find.byType(Icon),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
    handle.dispose();
  });

  testWidgets('a label is spoken once', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const MxIconTile(icon: Icons.star, semanticLabel: 'Starred'),
    );

    expect(find.bySemanticsLabel('Starred'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(Icon),
        matching: find.byType(ExcludeSemantics),
      ),
      findsNothing,
    );
    handle.dispose();
  });

  testWidgets('icon and child are mutually exclusive: neither throws', (
    tester,
  ) async {
    expect(() => MxIconTile(), throwsAssertionError);
  });

  testWidgets('icon and child are mutually exclusive: both throws', (
    tester,
  ) async {
    expect(
      () => MxIconTile(icon: Icons.tag, child: const Text('x')),
      throwsAssertionError,
    );
  });

  testWidgets('child renders untouched, no Icon is built', (tester) async {
    const childWidget = Text('A');
    await pump(tester, const MxIconTile(child: childWidget));

    expect(find.text('A'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(tester.widget<Text>(find.text('A')), same(childWidget));
  });
}
