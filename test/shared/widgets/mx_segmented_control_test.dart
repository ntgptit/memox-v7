import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_elevation.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_segmented_control.dart';

enum _Range { week, month, year }

/// Handoff SegmentedButton (D): a `surfaceContainer` track holding two or
/// three choices; the selected one floats as a `surfaceContainerLowest` pill
/// with `shadow-soft`. No production caller (owner decision 10).
void main() {
  Future<void> pump(
    WidgetTester tester, {
    _Range selected = _Range.week,
    ValueChanged<_Range>? onChanged,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: Center(
          child: MxSegmentedControl<_Range>(
            segments: const <MxSegment<_Range>>[
              MxSegment(value: _Range.week, label: 'Week'),
              MxSegment(value: _Range.month, label: 'Month'),
              MxSegment(value: _Range.year, label: 'Year'),
            ],
            selected: selected,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'track is surfaceContainer, the selected pill is lowest + shadow-soft',
    (tester) async {
      final scheme = buildLightTheme().colorScheme;
      await pump(tester);

      final track = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MxSegmentedControl<_Range>),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (track.decoration as BoxDecoration).color,
        scheme.surfaceContainer,
      );
      expect(
        (track.decoration as BoxDecoration).borderRadius,
        BorderRadius.circular(AppRadius.full),
      );

      final pill = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text('Week'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final decoration = pill.decoration! as BoxDecoration;
      expect(decoration.color, scheme.surfaceContainerLowest);
      expect(decoration.boxShadow, shadowsFor(AppElevation.card, scheme));
    },
  );

  testWidgets('the track is the 48 target, and so is every segment', (
    tester,
  ) async {
    await pump(tester);

    // Equal, not at-least: a segment that stretched to the height it was
    // offered would pass a floor while filling the screen.
    expect(
      tester.getSize(find.byType(MxSegmentedControl<_Range>)).height,
      AppSizing.touchTarget,
    );
    for (final label in <String>['Week', 'Month', 'Year']) {
      final target = find
          .ancestor(of: find.text(label), matching: find.byType(InkWell))
          .first;
      expect(
        tester.getSize(target).height,
        greaterThanOrEqualTo(AppSizing.touchTarget),
        reason: '$label is tapped through a box under the 48 floor',
      );
    }
  });

  testWidgets('tapping a segment selects it; semantics say which', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    _Range? picked;
    await pump(tester, onChanged: (v) => picked = v);

    await tester.tap(find.text('Month'));
    expect(picked, _Range.month);

    final week = tester.getSemantics(find.text('Week'));
    expect(week.label, 'Week');
    expect(week.flagsCollection.isSelected, Tristate.isTrue);
    expect(week.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    final month = tester.getSemantics(find.text('Month'));
    expect(month.flagsCollection.isSelected, Tristate.isFalse);
    handle.dispose();
  });

  test('two or three segments only', () {
    expect(
      () => MxSegmentedControl<int>(
        segments: const <MxSegment<int>>[MxSegment(value: 1, label: 'One')],
        selected: 1,
        onChanged: (_) {},
      ),
      throwsAssertionError,
    );
  });
}
