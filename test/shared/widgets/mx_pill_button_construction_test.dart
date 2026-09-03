import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';

/// How `MxPillButton` is *built*, pinned at source and at paint.
///
/// M100.32 chose `ChoiceChip.elevated` on the belief that the variant supplied
/// the unselected fill. `ChipThemeData.color` short-circuits the variant's
/// defaults, so the only thing the variant ever changed was the shadow — and
/// with `pressElevation` at the SDK's 1.0 every press cast one (#434 P1-2).
/// A note in the theme said the opposite for four releases; a test is what
/// would have contradicted it.
void main() {
  test('the pill is a flat ChoiceChip built shrink-wrapped', () {
    final String source = File(
      'lib/shared/widgets/mx_pill_button.dart',
    ).readAsStringSync();

    expect(
      source,
      isNot(contains('ChoiceChip.elevated')),
      reason: 'the elevated variant brings a real shadowColor with it',
    );
    expect(source, contains('ChoiceChip('));
    expect(
      source,
      contains('MaterialTapTargetSize.shrinkWrap'),
      reason:
          "`padded` puts RawChip's 48 box inside the focus ring; the target "
          'is grown outside it by _TapTarget',
    );
  });

  Future<void> pump(WidgetTester tester, {Color? ground}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: ColoredBox(
            color: ground ?? Colors.transparent,
            child: Center(
              child: MxPillButton(
                label: 'All',
                isSelected: false,
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  Material chipMaterial(WidgetTester tester) => tester.widget<Material>(
    find
        .descendant(
          of: find.byType(ChoiceChip),
          matching: find.byType(Material),
        )
        .first,
  );

  testWidgets('no elevation at rest and none while pressed', (tester) async {
    await pump(tester);
    expect(chipMaterial(tester).elevation, 0);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ChoiceChip)),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      chipMaterial(tester).elevation,
      0,
      reason: 'the press reached pressElevation — a second depth mechanism',
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('on a sheet the hairline is the only boundary, and it is there', (
    tester,
  ) async {
    // Inside a bottom sheet the ground *is* `surfaceContainerLow`, the same
    // role as the pill's fill, so the side is the one thing separating them.
    // 1.24:1 against the paper is accepted (#434 P2-4): the pill is identified
    // by shape, label, group and tick, the exemption a card's edge takes.
    final scheme = buildLightTheme().colorScheme;
    await pump(tester, ground: scheme.surfaceContainerLow);

    final chip = Theme.of(tester.element(find.byType(ChoiceChip))).chipTheme;
    final BorderSide side = (chip.side! as WidgetStateBorderSide).resolve(
      const <WidgetState>{},
    )!;
    expect(
      chip.color!.resolve(const <WidgetState>{}),
      scheme.surfaceContainerLow,
    );
    expect(side.color, scheme.outlineVariant);
    expect(side.color, isNot(scheme.surfaceContainerLow));
    expect(side.width, greaterThan(0));
  });
}
