import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';

/// `MxProgressBar` — the app's one determinate progress treatment.
///
/// **The colour assertions here are what the deck screen's visual audit points
/// at.** `LinearProgressIndicator` paints its track and its fill through
/// `_LinearProgressIndicatorPainter`, so neither colour reaches a render object
/// the auditor can read; the allowance in
/// `deck_list_screen_visual_audit_test.dart` names this file as the place they
/// are checked instead. Reading them off the widget rather than the raster is
/// the point — it is the same value the painter will use, without a screenshot
/// in between.
void main() {
  final light = buildLightTheme();

  Future<void> pumpApp(
    WidgetTester tester,
    Widget bar, {
    bool disableAnimations = false,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: light,
      home: Builder(
        // `copyWith` on the real data, never a fresh `MediaQueryData`:
        // constructing one zeroes `size` and `padding`, so the widget is told
        // the screen is 0x0 while the view says otherwise.
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: Scaffold(
            body: Padding(padding: const EdgeInsets.all(16), child: bar),
          ),
        ),
      ),
    ),
  );
  final semantic = light.extension<AppSemanticColors>()!;

  LinearProgressIndicator indicatorOf(WidgetTester tester) => tester
      .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));

  group('colour', () {
    testWidgets('below 100% the fill is progressFill, which v3 pins to '
        'primary', (tester) async {
      // **v3 fills progress with the accent** (`ui_kits/mobile/v3/screens/
      // _shared.jsx:241`, `StudyTopBar`'s own default) — `progressFill =
      // primary` (GC-2). The V1 "never the accent" rule this used to assert
      // is retired; what stands is the component's identity check, that the
      // widget paints `progressFill` and nothing it derived independently.
      await pumpApp(tester, const MxProgressBar(value: 0.62));
      await tester.pumpAndSettle();

      expect(indicatorOf(tester).color, semantic.progressFill);
      expect(indicatorOf(tester).color, light.colorScheme.primary);
    });

    testWidgets('at 100% the fill turns success', (tester) async {
      await pumpApp(tester, const MxProgressBar(value: 1));
      await tester.pumpAndSettle();

      expect(indicatorOf(tester).color, semantic.success);
    });

    testWidgets('the track is the progress track token', (tester) async {
      await pumpApp(tester, const MxProgressBar(value: 0.3));
      await tester.pumpAndSettle();

      expect(indicatorOf(tester).backgroundColor, semantic.progressTrack);
    });
  });

  group('value', () {
    testWidgets('is clamped rather than asserted', (tester) async {
      // A caller dividing by a deck with no cards is a real case, and a bar
      // drawn past its own track is a rendering bug shipped to a user instead of
      // a number caught here.
      await pumpApp(tester, const MxProgressBar(value: 4.2));
      await tester.pumpAndSettle();

      expect(indicatorOf(tester).value, 1);
    });

    testWidgets('a negative value floors at zero', (tester) async {
      await pumpApp(tester, const MxProgressBar(value: -1));
      await tester.pumpAndSettle();

      expect(indicatorOf(tester).value, 0);
    });

    testWidgets('animates to a new value rather than jumping', (tester) async {
      await pumpApp(tester, const MxProgressBar(value: 0));
      await tester.pumpAndSettle();

      await pumpApp(tester, const MxProgressBar(value: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final midway = indicatorOf(tester).value!;
      expect(midway, greaterThan(0));
      expect(
        midway,
        lessThan(1),
        reason: 'a bar that snaps has finished moving before anyone looks',
      );
    });
  });

  group('reduced motion', () {
    testWidgets('the sweep is gone, and the value that arrives is the same', (
      tester,
    ) async {
      // The sweep is decoration on a value change, not the value itself. With
      // the platform flag on, the bar has to land on the new figure in the
      // frame it changes — not sweep faster, and not skip the figure.
      await pumpApp(
        tester,
        const MxProgressBar(value: 0),
        disableAnimations: true,
      );
      await tester.pumpAndSettle();

      await pumpApp(
        tester,
        const MxProgressBar(value: 1),
        disableAnimations: true,
      );
      await tester.pump();

      expect(
        indicatorOf(tester).value,
        1,
        reason: 'the bar was still animating with animations disabled',
      );
    });

    testWidgets('the colour and the announced label do not change with it', (
      tester,
    ) async {
      // The accessibility contract removes movement, never information. A
      // reduced-motion build that also dropped the success colour or the
      // announcement would be answering a different request.
      final handle = tester.ensureSemantics();

      await pumpApp(
        tester,
        const MxProgressBar(value: 1, label: '20 of 20 learned'),
        disableAnimations: true,
      );
      await tester.pump();

      expect(indicatorOf(tester).color, semantic.success);
      expect(find.bySemanticsLabel('20 of 20 learned'), findsOneWidget);
      handle.dispose();
    });
  });

  group('the header', () {
    testWidgets('is absent entirely when neither label is given', (
      tester,
    ) async {
      await pumpApp(tester, const MxProgressBar(value: 0.5));
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('shows both labels when both are given', (tester) async {
      await pumpApp(
        tester,
        const MxProgressBar(
          value: 0.5,
          label: '20 of 40 learned',
          valueLabel: '50%',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('20 of 40 learned'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });
  });

  group('semantics', () {
    testWidgets('announces the label and the figure once, not twice', (
      tester,
    ) async {
      // The header is excluded from the tree on purpose: without that, a screen
      // reader reads the label, then the figure, then the same two again from
      // the `Semantics` wrapper.
      final handle = tester.ensureSemantics();

      await pumpApp(
        tester,
        const MxProgressBar(
          value: 0.5,
          label: '20 of 40 learned',
          valueLabel: '50%',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('20 of 40 learned'),
        findsOneWidget,
        reason: 'the wrapper announces it, the header does not',
      );
      handle.dispose();
    });
  });

  group('size', () {
    testWidgets('sm is thinner than md', (tester) async {
      await pumpApp(
        tester,
        const MxProgressBar(value: 0.5, size: MxProgressBarSize.sm),
      );
      await tester.pumpAndSettle();
      final small = indicatorOf(tester).minHeight!;

      await pumpApp(tester, const MxProgressBar(value: 0.5));
      await tester.pumpAndSettle();

      expect(small, lessThan(indicatorOf(tester).minHeight!));
    });
  });

  group('overrides', () {
    // MxSessionTopBar is the one caller that passes these; every other
    // caller leaves them null and is covered by the groups above.
    const overrideAccent = Color(0xFF123456);

    testWidgets('fillColor wins over progressFill and over success', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const MxProgressBar(value: 0.5, fillColor: overrideAccent),
      );
      await tester.pumpAndSettle();
      expect(indicatorOf(tester).color, overrideAccent);

      // Even at 100%, where the un-overridden widget turns `success` — the
      // override is the caller's colour, not a colour this widget picks for
      // itself.
      await pumpApp(
        tester,
        const MxProgressBar(value: 1, fillColor: overrideAccent),
      );
      await tester.pumpAndSettle();
      expect(indicatorOf(tester).color, overrideAccent);
    });

    testWidgets('null fillColor keeps today\'s progressFill/success pick', (
      tester,
    ) async {
      await pumpApp(tester, const MxProgressBar(value: 0.5));
      await tester.pumpAndSettle();
      expect(indicatorOf(tester).color, semantic.progressFill);
    });

    testWidgets('duration overrides the sweep\'s AppDurations.slow default', (
      tester,
    ) async {
      // `slow` (320ms) has not finished at 60ms past a value change; a
      // shorter override should have.
      await pumpApp(
        tester,
        const MxProgressBar(value: 0, duration: Duration(milliseconds: 40)),
      );
      await tester.pumpAndSettle();

      await pumpApp(
        tester,
        const MxProgressBar(value: 1, duration: Duration(milliseconds: 40)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(
        indicatorOf(tester).value,
        1,
        reason: 'a 40ms override should be done well before 60ms has passed',
      );
    });
  });
}
