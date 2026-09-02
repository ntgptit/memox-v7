import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/presentation/widgets/items/progress_week_bar_widget.dart';

import '../../../support/color_math.dart';
import 'support/fake_progress_repository.dart';
import 'support/progress_screen_harness.dart';

/// The activity chart's bar is a **graphic**, and WCAG 1.4.11 asks 3:1 of it.
///
/// **The strict visual audit cannot see this pair.** `NonTextContrastRule`
/// inspects paints whose role is a *border*, and the chart's fill and track are
/// backgrounds; its `informationalColors` list carries the focus ring and the
/// four status hues and neither of these. So the one contrast obligation this
/// screen adds to the app is exactly the one the screen audit does not cover,
/// and it needs an assertion of its own rather than a note saying it was
/// checked once by hand.
///
/// **The pair that carries meaning is fill-against-track**, not fill-against-
/// page: the length of the filled part is read against the track behind it, and
/// a fill that disappeared into its own track would leave the bar saying
/// nothing. Measured at the time of writing: **3.34:1** in light
/// (`progressFillLight` on `progressTrackLight`) and **4.08:1** in dark. Both
/// clear the floor, and light clears it by 0.34 — which is the whole reason
/// this is pinned rather than left to a future palette tweak to discover.
void main() {
  /// WCAG 1.4.11 for a non-text graphic.
  const double graphicFloor = 3;

  for (final (String mode, ThemeData Function() build)
      in <(String, ThemeData Function())>[
        ('light', buildLightTheme),
        ('dark', buildDarkTheme),
      ]) {
    test('$mode: the chart fill clears 3:1 against its own track', () {
      final AppSemanticColors semantic = build()
          .extension<AppSemanticColors>()!;

      expect(
        contrast(semantic.progressFill, semantic.progressTrack),
        greaterThanOrEqualTo(graphicFloor),
        reason:
            'the filled length is read against the track behind it; below 3:1 '
            'the bar stops carrying its value (WCAG 1.4.11)',
      );
    });
  }

  test('the track is deliberately quiet, and the numbers carry the meaning', () {
    // **Recorded, not enforced at 3:1 — and the difference is the point.** The
    // track against the card surface measures 1.27:1 in light and 1.35:1 in
    // dark, far below the graphic floor. That is allowed because the track is
    // not what conveys the value: every row states its count in text and names
    // its day, and the bar is `ExcludeSemantics` decoration (P5). WCAG 1.4.11
    // applies to graphics *required to understand the content*, and this one is
    // not.
    //
    // The assertion is here anyway so the number is in the suite rather than in
    // a review comment: `progressTrack` is the app's shared progress track, so
    // raising it is a design decision for every bar at once, and this test is
    // where a future change to it will show up as a deliberate edit.
    final AppSemanticColors light = buildLightTheme()
        .extension<AppSemanticColors>()!;
    final AppSemanticColors dark = buildDarkTheme()
        .extension<AppSemanticColors>()!;

    expect(
      contrast(light.progressTrack, buildLightTheme().colorScheme.surface),
      lessThan(graphicFloor),
    );
    expect(
      contrast(dark.progressTrack, buildDarkTheme().colorScheme.surface),
      lessThan(graphicFloor),
    );
  });

  /// The busiest day stays `progressFill`, and never becomes `success` (X5).
  ///
  /// **This is the difference the shared component would have introduced.**
  /// `MxProgressBar` turns its fill `success` at `fraction >= 1`, which is right
  /// where 100% means finished — a deck's progress. Here the scale is the
  /// busiest day of the week, so every week anybody has ever studied has a day
  /// at exactly 1.0, and borrowing the component would paint one green "done"
  /// bar per week on a chart where finishing is not a thing that happens.
  ///
  /// Rendered rather than reasoned about, because the two colours are both valid
  /// tokens: the strict visual audit accepts either, and a token-only assertion
  /// would agree with whichever one the widget picked.
  for (final ({String name, bool isDark}) theme
      in const <({String name, bool isDark})>[
        (name: 'light', isDark: false),
        (name: 'dark', isDark: true),
      ]) {
    testWidgets('the busiest day is a progress fill, not a success fill '
        '(${theme.name})', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository(
          initial: progressOverviewFixture(
            totals: const <int>[0, 1, 2, 3, 4, 5, 10],
            streakDays: 5,
            today: DateTime.utc(2026, 8, 12),
          ),
        ),
        isDark: theme.isDark,
      );

      final AppSemanticColors semantic =
          (theme.isDark ? buildDarkTheme() : buildLightTheme())
              .extension<AppSemanticColors>()!;
      final fills = find
          .descendant(
            of: find.byType(ProgressWeekBarWidget),
            matching: find.descendant(
              of: find.byType(FractionallySizedBox),
              matching: find.byType(DecoratedBox),
            ),
          )
          .evaluate()
          .map(
            (element) =>
                ((element.widget as DecoratedBox).decoration as BoxDecoration)
                    .color,
          )
          .toList();

      expect(fills, hasLength(7));
      for (final Color? fill in fills) {
        expect(fill, semantic.progressFill);
        expect(fill, isNot(semantic.success));
      }
    });
  }
}
