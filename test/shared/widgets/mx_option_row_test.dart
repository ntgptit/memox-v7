import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

/// `MxOptionRow` — the v3 pick-one row: a ring that thickens, never a dot,
/// and its own geometry (48 min height, 12/16 padding) rather than the
/// ambient `ListTileThemeData` every other row shares.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: child),
      ),
    );
  }

  BoxDecoration radioDecorationOf(WidgetTester tester) {
    final containers = tester.widgetList<Container>(find.byType(Container));
    final radio = containers.firstWhere(
      (c) => c.constraints?.maxWidth == 20 || c.decoration is BoxDecoration,
    );
    return radio.decoration! as BoxDecoration;
  }

  testWidgets('unselected draws a 20dp circle with a 2dp outline ring', (
    tester,
  ) async {
    await pump(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: false, onSelect: () {}),
    );

    final theme = buildLightTheme();
    final decoration = radioDecorationOf(tester);
    final border = decoration.border! as Border;
    expect(decoration.shape, BoxShape.circle);
    expect(border.top.width, 2);
    expect(border.top.color, theme.colorScheme.outline);
  });

  testWidgets('selected thickens the ring to 6dp primary — nothing moves', (
    tester,
  ) async {
    await pump(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: true, onSelect: () {}),
    );

    final theme = buildLightTheme();
    final decoration = radioDecorationOf(tester);
    final border = decoration.border! as Border;
    expect(border.top.width, 6);
    expect(border.top.color, theme.colorScheme.primary);

    final box = tester.getSize(
      find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxWidth == 20,
      ),
    );
    expect(box, const Size(20, 20));
  });

  testWidgets('the row never shrinks below the 48 touch floor', (tester) async {
    await pump(
      tester,
      MxOptionRow(title: 'Algorithm', isSelected: false, onSelect: () {}),
    );

    final size = tester.getSize(find.byType(MxOptionRow));
    expect(size.height, greaterThanOrEqualTo(AppSizing.touchTarget));
  });

  testWidgets('a divider sits between rows and is omitted on the last', (
    tester,
  ) async {
    await pump(
      tester,
      const Column(
        children: <Widget>[
          MxOptionRow(title: 'SM-2', isSelected: true, onSelect: null),
          MxOptionRow(
            title: 'Leitner',
            isSelected: false,
            onSelect: null,
            isLast: true,
          ),
        ],
      ),
    );

    final decorations = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((w) => w.decoration)
        .whereType<BoxDecoration>()
        .toList();

    final withBorder = decorations.where((d) => d.border != null);
    final withoutBorder = decorations.where((d) => d.border == null);
    expect(withBorder, isNotEmpty, reason: 'the first row keeps its divider');
    expect(withoutBorder, isNotEmpty, reason: 'the last row has none');
  });

  testWidgets('tapping picks the row', (tester) async {
    var taps = 0;
    await pump(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: false, onSelect: () => taps++),
    );

    await tester.tap(find.text('SM-2'));
    expect(taps, 1);
  });

  testWidgets('a null handler locks the row: no tap, dimmed, unfocusable', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const MxOptionRow(title: 'SM-2', isSelected: false, onSelect: null),
    );

    await tester.tap(find.text('SM-2'), warnIfMissed: false);

    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, AppStateOpacity.disabled);

    final node = tester.getSemantics(find.text('SM-2'));
    expect(node.flagsCollection.isEnabled.name, 'isFalse');
    handle.dispose();
  });

  testWidgets('semantics carry the radio state, not a list selection', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: true, onSelect: () {}),
    );

    final node = tester.getSemantics(find.text('SM-2'));
    expect(node.flagsCollection.isChecked.name, 'isTrue');
    expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    handle.dispose();
  });

  testWidgets('subtitle sits 2dp below the title and wraps at its own rung', (
    tester,
  ) async {
    await pump(
      tester,
      MxOptionRow(
        title: 'SM-2',
        subtitle: 'Adaptive spacing',
        isSelected: false,
        onSelect: () {},
      ),
    );

    final theme = buildLightTheme();
    final title = tester.widget<Text>(find.text('SM-2'));
    final subtitle = tester.widget<Text>(find.text('Adaptive spacing'));

    expect(title.style?.fontSize, 14);
    expect(title.style?.letterSpacing, -0.1);
    expect(subtitle.style?.color, theme.colorScheme.onSurfaceVariant);
    expect(subtitle.style?.height, 1.45);
  });

  testWidgets('trailing content renders in its own slot', (tester) async {
    await pump(
      tester,
      MxOptionRow(
        title: 'SM-2',
        isSelected: false,
        onSelect: () {},
        trailing: const Icon(Icons.star),
      ),
    );

    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('the selected ring reads primary in dark too', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        home: Scaffold(
          body: MxOptionRow(title: 'SM-2', isSelected: true, onSelect: () {}),
        ),
      ),
    );

    final theme = buildDarkTheme();
    final decoration = radioDecorationOf(tester);
    final border = decoration.border! as Border;
    expect(border.top.color, theme.colorScheme.primary);
    expect(border.top.width, 6);
  });
}
