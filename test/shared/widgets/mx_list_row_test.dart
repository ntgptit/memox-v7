import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_icon.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

void main() {
  group('MxListRow content', () {
    testWidgets('renders title and subtitle, each one line with ellipsis', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(
            body: MxListRow(title: 'Academic Word List', subtitle: '120 cards'),
          ),
        ),
      );

      final Text title = tester.widget(find.text('Academic Word List'));
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);

      final Text subtitle = tester.widget(find.text('120 cards'));
      expect(subtitle.maxLines, 1);
      expect(subtitle.overflow, TextOverflow.ellipsis);
    });

    testWidgets('omits the subtitle row when none is given', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: MxListRow(title: 'Academic Word List')),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('is exactly 48dp tall with only a title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: MxListRow(title: 'Academic Word List')),
        ),
      );

      final Size size = tester.getSize(find.byType(MxListRow));
      expect(size.height, equals(48));
    });

    testWidgets('sets the title at wght 600 through the variable axis', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: MxListRow(title: 'Academic Word List')),
        ),
      );

      final Text title = tester.widget(find.text('Academic Word List'));
      final TextStyle style = title.style!;
      expect(style.fontWeight, FontWeight.w600);
      expect(style.letterSpacing, -0.1);
      expect(style.fontVariations, contains(const FontVariation('wght', 600)));
    });

    testWidgets('leadingIcon builds the default MxIconTile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(
            body: MxListRow(
              title: 'Academic Word List',
              leadingIcon: Icons.layers_outlined,
            ),
          ),
        ),
      );

      final MxIconTile tile = tester.widget(find.byType(MxIconTile));
      expect(tile.size, MxIconTileSize.sm);
      expect(tester.getSize(find.byType(MxIconTile)), const Size(28, 28));
    });

    testWidgets('leading overrides the default tile entirely', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(
            body: MxListRow(
              title: 'Academic Word List',
              leadingIcon: Icons.layers_outlined,
              leading: Icon(Icons.star),
            ),
          ),
        ),
      );

      expect(find.byType(MxIconTile), findsNothing);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders no leading slot when neither is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: MxListRow(title: 'Academic Word List')),
        ),
      );

      expect(find.byType(MxIconTile), findsNothing);
    });

    testWidgets('trailing overrides the default glyph entirely', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(
            body: MxListRow(
              title: 'Academic Word List',
              trailingIcon: Icons.chevron_right,
              trailing: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'trailingIcon builds the default glyph, coloured onSurfaceVariant',
      (tester) async {
        final ThemeData theme = buildLightTheme();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: MxListRow(
                title: 'Academic Word List',
                trailingIcon: Icons.chevron_right,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
        final Icon icon = tester.widget(find.byIcon(Icons.chevron_right));
        expect(icon.color, theme.colorScheme.onSurfaceVariant);
      },
    );

    testWidgets('renders no trailing slot when neither is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: MxListRow(title: 'Academic Word List')),
        ),
      );

      expect(find.byType(MxIcon), findsNothing);
    });
  });

  group('MxListRow divider', () {
    testWidgets('shows the bottom hairline by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(body: MxListRow(title: 'Academic Word List')),
        ),
      );

      final DecoratedBox box = tester.widget(find.byType(DecoratedBox).first);
      final BoxDecoration decoration = box.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('omits the hairline when hasDivider is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(
            body: MxListRow(title: 'Academic Word List', hasDivider: false),
          ),
        ),
      );

      expect(find.byType(DecoratedBox), findsNothing);
    });
  });

  group('MxListRow tap behaviour', () {
    testWidgets(
      'a null onTap renders plain content: no InkWell, no button semantics',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(body: MxListRow(title: 'Academic Word List')),
          ),
        );

        expect(find.byType(InkWell), findsNothing);
        final SemanticsNode node = tester.getSemantics(find.byType(MxListRow));
        expect(node.flagsCollection.isButton, isFalse);
        handle.dispose();
      },
    );

    testWidgets('a non-null onTap exposes a button and fires on tap', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: MxListRow(
              title: 'Academic Word List',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
      final SemanticsNode node = tester.getSemantics(find.byType(MxListRow));
      expect(node.flagsCollection.isButton, isTrue);

      await tester.tap(find.byType(MxListRow));
      await tester.pump();
      expect(tapped, isTrue);
      handle.dispose();
    });

    testWidgets('a semanticLabel merges the row into one announced node', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: MxListRow(
              title: 'Academic Word List',
              subtitle: '120 cards',
              onTap: () {},
              semanticLabel: 'Academic Word List, 120 cards',
            ),
          ),
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.byType(MxListRow));
      expect(node.label, 'Academic Word List, 120 cards');
      handle.dispose();
    });
  });
}
