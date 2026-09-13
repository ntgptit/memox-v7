import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/shared/widgets/mx_icon.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

/// Handoff IconTile (C): a tinted square, sm 28 / md 36 / lg 44, primary at
/// 10%, radius 8, non-interactive. Glyph per size is D4.
void main() {
  for (final (MxIconTileSize size, double extent, MxIconSize glyph)
      in <(MxIconTileSize, double, MxIconSize)>[
        (MxIconTileSize.sm, 28, MxIconSize.xs),
        (MxIconTileSize.md, 36, MxIconSize.sm),
        (MxIconTileSize.lg, 44, MxIconSize.md),
      ]) {
    testWidgets('${size.name} is $extent with a ${glyph.name} glyph', (
      tester,
    ) async {
      final theme = buildLightTheme();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: MxIconTile(icon: Icons.folder_outlined, size: size),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(MxIconTile)), Size.square(extent));
      expect(tester.widget<MxIcon>(find.byType(MxIcon)).size, glyph);
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MxIconTile),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(AppRadius.sm));
      // The handoff's `primary` at 10%, resolved against the card surface the
      // tile sits on rather than left translucent (design_audit R7).
      expect(
        decoration.color,
        Color.alphaBlend(
          theme.colorScheme.primary.withValues(alpha: 0.10),
          theme.colorScheme.surfaceContainerLowest,
        ),
      );
      expect(find.byType(InkWell), findsNothing);
    });
  }
}
