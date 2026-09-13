import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// Handoff IconButton (B): a 36 ink box, a 20 glyph, a 48 hit target, and an
/// 8% primary tint behind the glyph (14% in dark). App-bar actions keep the
/// Foundations' 24 glyph (D16).
void main() {
  Future<void> pump(
    WidgetTester tester, {
    MxIconButtonPlacement placement = MxIconButtonPlacement.content,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: Center(
          child: MxIconButton(
            icon: Icons.search,
            semanticLabel: 'Search',
            onPressed: () {},
            placement: placement,
          ),
        ),
      ),
    ),
  );

  testWidgets('paints a 36 circle inside a 48 target', (tester) async {
    await pump(tester);

    expect(tester.getSize(find.byType(IconButton)), const Size.square(48));
    final ink = find
        .descendant(
          of: find.byType(IconButton),
          matching: find.byType(Material),
        )
        .first;
    expect(tester.getSize(ink), const Size.square(AppSizing.iconButtonInk));
    expect(tester.widget<Material>(ink).shape, isA<CircleBorder>());
  });

  testWidgets('content glyph is 20, bar glyph is 24', (tester) async {
    await pump(tester);
    expect(tester.widget<Icon>(find.byType(Icon)).size, AppIconSize.sm);

    await pump(tester, placement: MxIconButtonPlacement.bar);
    expect(tester.widget<Icon>(find.byType(Icon)).size, AppIconSize.md);
  });

  test('hover and press tint primary at 8% light, 14% dark', () {
    for (final (theme, alpha) in <(ThemeData, double)>[
      (buildLightTheme(), AppStateOpacity.iconTintLight),
      (buildDarkTheme(), AppStateOpacity.iconTintDark),
    ]) {
      final overlay = theme.iconButtonTheme.style!.overlayColor!;
      final expected = theme.colorScheme.primary.withValues(alpha: alpha);
      expect(overlay.resolve(<WidgetState>{WidgetState.pressed}), expected);
      expect(overlay.resolve(<WidgetState>{WidgetState.hovered}), expected);
    }
    expect(AppStateOpacity.iconTintLight, 0.08);
    expect(AppStateOpacity.iconTintDark, 0.14);
  });
}
