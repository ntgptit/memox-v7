import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/shared/widgets/mx_slider.dart';

/// Handoff Slider (D): `primary` active, `surfaceContainerHighest` inactive,
/// a 12% halo. No production caller (owner decision 10).
void main() {
  test('theme: primary active, surfaceContainerHighest inactive, 12% halo', () {
    for (final theme in <ThemeData>[buildLightTheme(), buildDarkTheme()]) {
      final slider = theme.sliderTheme;
      final scheme = theme.colorScheme;
      expect(slider.activeTrackColor, scheme.primary);
      expect(slider.inactiveTrackColor, scheme.surfaceContainerHighest);
      expect(slider.inactiveTickMarkColor, scheme.onSurfaceVariant);
      expect(
        slider.overlayColor,
        scheme.primary.withValues(alpha: AppStateOpacity.pressed),
      );
    }
  });

  testWidgets('the slider node carries the name and reports changes', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    double? value;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: MxSlider(
            value: 0.5,
            onChanged: (v) => value = v,
            semanticLabel: 'Daily goal',
          ),
        ),
      ),
    );

    // Read off the slider, not found by label: a label on a node the slider is
    // not merged into would be found by label and still leave the slider
    // itself unnamed. `getSemanticsData` is the merged node a reader focuses.
    final data = tester.getSemantics(find.byType(Slider)).getSemanticsData();
    expect(data.label, 'Daily goal');
    expect(data.flagsCollection.isSlider, isTrue);
    expect(data.hasAction(SemanticsAction.increase), isTrue);

    await tester.drag(find.byType(Slider), const Offset(60, 0));
    expect(value, isNotNull);
    handle.dispose();
  });
}
