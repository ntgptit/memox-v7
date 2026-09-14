import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_switch.dart';
import 'package:memox/shared/widgets/mx_switch_row.dart';

/// Handoff Switch (D): 44 × 26 track, 20 thumb inset 3, `surfaceBright` thumb,
/// `surfaceContainerHighest` off / `primary` on, 160ms.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool isOn,
    ValueChanged<bool>? onChanged,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: MxSwitchRow(label: 'Reminders', isOn: isOn, onChanged: onChanged),
      ),
    ),
  );

  final thumb = find.descendant(
    of: find.byType(MxSwitch),
    matching: find.byWidgetPredicate(
      (w) =>
          w is SizedBox &&
          w.width == AppSizing.switchThumb &&
          w.height == AppSizing.switchThumb,
    ),
  );

  // The track is the switch's own root, so the finder has to match it.
  Color trackColor(WidgetTester tester) =>
      ((tester
                  .widget<AnimatedContainer>(
                    find.descendant(
                      of: find.byType(MxSwitch),
                      matching: find.byType(AnimatedContainer),
                      matchRoot: true,
                    ),
                  )
                  .decoration!)
              as BoxDecoration)
          .color!;

  Color thumbColor(WidgetTester tester) =>
      ((tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byType(MxSwitch),
                      matching: find.byWidgetPredicate(
                        (w) =>
                            w is DecoratedBox &&
                            (w.decoration as BoxDecoration).shape ==
                                BoxShape.circle,
                      ),
                    ),
                  )
                  .decoration)
              as BoxDecoration)
          .color!;

  testWidgets('track and thumb geometry', (tester) async {
    await pump(tester, isOn: false, onChanged: (_) {});
    expect(
      tester.getSize(find.byType(MxSwitch)),
      const Size(AppSizing.switchTrackWidth, AppSizing.switchTrackHeight),
    );
    expect(thumb, findsOneWidget);
    final track = tester.getRect(find.byType(MxSwitch));
    expect(tester.getRect(thumb).left - track.left, AppSizing.switchThumbInset);

    await pump(tester, isOn: true, onChanged: (_) {});
    await tester.pumpAndSettle();
    expect(
      tester.getRect(thumb).left - tester.getRect(find.byType(MxSwitch)).left,
      AppSizing.switchTrackWidth -
          AppSizing.switchThumb -
          AppSizing.switchThumbInset,
    );
  });

  testWidgets('colours: track off/on, thumb surfaceBright', (tester) async {
    final scheme = buildLightTheme().colorScheme;

    await pump(tester, isOn: false, onChanged: (_) {});
    expect(trackColor(tester), scheme.surfaceContainerHighest);
    expect(thumbColor(tester), scheme.surfaceBright);

    await pump(tester, isOn: true, onChanged: (_) {});
    await tester.pumpAndSettle();
    expect(trackColor(tester), scheme.primary);
    expect(thumbColor(tester), scheme.surfaceBright);
  });

  testWidgets('disabled keeps a colour per slot (D3)', (tester) async {
    final semantic = buildLightTheme().extension<AppSemanticColors>()!;

    await pump(tester, isOn: true);
    expect(trackColor(tester), semantic.disabledSurface);
    expect(thumbColor(tester), semantic.onDisabled);
  });

  testWidgets('the row toggles and announces one toggled node', (tester) async {
    final handle = tester.ensureSemantics();
    bool? changed;
    await pump(tester, isOn: false, onChanged: (v) => changed = v);

    await tester.tap(find.text('Reminders'));
    expect(changed, isTrue);

    final node = tester.getSemantics(find.byType(MxSwitchRow));
    expect(node.label, 'Reminders');
    expect(node.flagsCollection.isToggled, Tristate.isFalse);
    expect(
      tester.getSize(find.byType(MxSwitchRow)).height,
      greaterThanOrEqualTo(AppSizing.touchTarget),
    );
    handle.dispose();
  });

  testWidgets('a null handler disables the row and says so', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, isOn: true);
    final node = tester.getSemantics(find.byType(MxSwitchRow));
    expect(node.flagsCollection.isEnabled, Tristate.isFalse);
    handle.dispose();
  });
}
