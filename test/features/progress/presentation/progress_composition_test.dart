import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/domain/models/deck_activity_snapshot_model.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_range_selector_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_streak_hero_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_screen_harness.dart';
import 'package:memox/core/theme/foundations/app_surface_colors.dart';

/// `/progress` as **one** screen: the overview's three sections and the library
/// level in the same scroll, fed by two independent streams (UC-12, UC-13,
/// M99.24).
///
/// **This is the seam the merge created, and nothing else covers it.** The two
/// halves arrived as separate features with a test file each, and both suites
/// still pass with either half rendering alone — `progress_screen_updates_test`
/// drives the overview, `progress_deck_screen_test` drives the level. What
/// neither can see is the failure mode composition introduces: one stream
/// emitting rebuilds the widget that *hosts* the other, so an answer landing in
/// the header can drop the level back to a spinner over rows it already has,
/// and the user watching the numbers update loses their place in the list.
///
/// **Proved by mutation rather than asserted to be useful.** Giving the composed
/// `ProgressDeckScreen` a `UniqueKey()` — one line, and exactly what "the header
/// rebuild recreates the level" means to the element tree — turns the middle
/// test red. Without that check this file would have been three tests that
/// cannot fail, which is the shape a composition test naturally takes: both
/// halves are on screen either way.
void main() {
  final english = AppLocalizationsEn();

  /// A repository whose level stream a test can push to, unlike the seeded
  /// factories — the subject here is what a *second* emission does.
  ({
    FakeProgressRepository repository,
    StreamController<DeckActivitySnapshot> level,
  })
  composed(DeckActivitySnapshot first) {
    final level = StreamController<DeckActivitySnapshot>.broadcast();
    addTearDown(level.close);

    return (
      repository: FakeProgressRepository(
        initial: progressOverviewFixture(
          totals: const <int>[1, 1, 1, 1, 1, 1, 2],
          streakDays: 3,
        ),
        activity: (String? deckId) async* {
          yield first;
          yield* level.stream;
        },
      ),
      level: level,
    );
  }

  DeckActivitySnapshot levelWith({required int activeCards}) =>
      activitySnapshot(
        scopeLast7Days: activityMetrics(
          activeCards: activeCards,
          activeDays: 4,
        ),
        decks: <DeckActivity>[
          deckActivity(
            deckId: 'deck-spanish',
            name: 'Spanish',
            last7Days: activityMetrics(activeCards: activeCards, activeDays: 4),
          ),
        ],
      );

  /// Where the one scroll view is, in pixels.
  ///
  /// One `Scrollable`, asserted rather than assumed: two would mean the header
  /// scrolls independently of the level, which is the composition this file
  /// exists to rule out.
  ScrollPosition positionOf(WidgetTester tester) {
    final scrollables = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    );
    expect(scrollables, findsOneWidget);

    return tester.state<ScrollableState>(scrollables).position;
  }

  /// Brings the deck rows onto the surface.
  ///
  /// **They start below the fold, and that is measured, not assumed** — with the
  /// three overview sections above it the first row sits past 852dp on the test
  /// surface, so `SliverList` has not built it. A `find.text` before this scroll
  /// finds nothing, which is why the level assertions here all run after it.
  Future<void> scrollToRows(WidgetTester tester) async {
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump();
  }

  testWidgets('both halves live in one scroll view', (tester) async {
    final parts = composed(levelWith(activeCards: 42));
    await pumpProgressScreen(tester, repository: parts.repository);

    expect(find.byType(ProgressStreakHeroWidget), findsOneWidget);
    expect(find.byType(ProgressSummaryWidget), findsOneWidget);
    expect(find.byType(MxLoadingState), findsNothing);

    await scrollToRows(tester);
    expect(find.text('Spanish'), findsOneWidget);
  });

  testWidgets('an overview emission leaves the level where it was', (
    tester,
  ) async {
    final parts = composed(levelWith(activeCards: 42));
    await pumpProgressScreen(tester, repository: parts.repository);
    await scrollToRows(tester);
    final double before = positionOf(tester).pixels;
    expect(before, greaterThan(0), reason: 'the scroll actually moved');

    parts.repository.emit(
      progressOverviewFixture(
        totals: const <int>[1, 1, 1, 1, 1, 1, 9],
        streakDays: 3,
      ),
    );
    // Frame by frame: a spinner that comes and goes inside `pumpAndSettle` is
    // still a flash, and it is the level's own `MxAsyncView` that would produce
    // it — the header rebuilding is what re-runs its build.
    await tester.pump();
    expect(find.byType(MxLoadingState), findsNothing, reason: 'rebuild frame');
    await tester.pump();

    expect(find.text('Spanish'), findsOneWidget);
    expect(find.byType(MxLoadingState), findsNothing);
    // The user's place in the list, which is the part a spinner assertion alone
    // would miss: a level rebuilt from scratch scrolls back to the top and the
    // rows are still on screen either way.
    expect(positionOf(tester).pixels, before);
  });

  testWidgets('the range selector travels with the overview, then sticks', (
    tester,
  ) async {
    // X10: pinned to the top of the *body* put the selector above the three
    // overview sections it does not govern — pressing `30 days` changed nothing
    // in the 24dp under it. Pinned from inside the scroll view, it starts below
    // the overview and only then sticks, which is what BR-187 actually needs.
    final parts = composed(levelWith(activeCards: 42));
    await pumpProgressScreen(tester, repository: parts.repository);

    final Rect hero = tester.getRect(find.byType(ProgressStreakHeroWidget));
    final Rect atRest = tester.getRect(
      find.byType(ProgressRangeSelectorWidget),
    );
    expect(
      atRest.top,
      greaterThan(hero.bottom),
      reason: 'at rest it sits below the overview, not above it',
    );

    await scrollToRows(tester);
    final Rect pinned = tester.getRect(
      find.byType(ProgressRangeSelectorWidget),
    );
    expect(
      pinned.top,
      lessThan(atRest.top),
      reason: 'it moved up with the scroll',
    );
    // Still on screen after the scroll that took the overview off it — the
    // whole point of pinning, and what a plain sliver would fail.
    expect(pinned.bottom, lessThanOrEqualTo(852.0));
    expect(find.byType(ProgressRangeSelectorWidget), findsOneWidget);
    // And the rows scroll *under* it rather than beside it.
    expect(pinned.top, lessThan(tester.getRect(find.text('Spanish')).top));
  });

  group('the band survives every face of the level', () {
    // The overview is a fact about the whole library. A level that is still
    // loading, or whose read failed, says nothing about the streak — and both
    // faces used to replace the entire screen, so a deck query that timed out
    // took three sections of real data with it.

    testWidgets('a level still loading keeps the header above the spinner', (
      tester,
    ) async {
      final never = StreamController<DeckActivitySnapshot>.broadcast();
      addTearDown(never.close);
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository(
          initial: progressOverviewFixture(
            totals: const <int>[1, 1, 1, 1, 1, 1, 2],
            streakDays: 3,
          ),
          activity: (String? deckId) => never.stream,
        ),
      );
      // `pump`, not `pumpAndSettle`: settling on a level that never answers
      // would time out on the spinner this test is about.
      await tester.pump();

      expect(find.byType(MxLoadingState), findsOneWidget);
      expect(find.byType(ProgressStreakHeroWidget), findsOneWidget);
      expect(find.text(english.progressTodayCardsLabel(2)), findsOneWidget);
    });

    testWidgets('a level that failed keeps the header above the error', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository.failing(
          const DatabaseFailure(message: 'level read failed'),
        ),
      );

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.byType(ProgressStreakHeroWidget), findsOneWidget);
      // Four, not two: `failing` seeds the fake's own default overview rather
      // than this file's, and the point is that whatever the header holds is
      // still on screen.
      expect(find.text(english.progressTodayCardsLabel(4)), findsOneWidget);
    });
  });

  testWidgets('the loaded screen meets the tap-target guidelines', (
    tester,
  ) async {
    // **The face with the most targets, and the one the sweep was missing.**
    // The guideline check ran on the error and empty faces, which have one
    // button each; the composed loaded screen has the two range pills and a row
    // per deck, and it is the screen the tab opens on.
    final handle = tester.ensureSemantics();
    final parts = composed(levelWith(activeCards: 42));
    await pumpProgressScreen(tester, repository: parts.repository);
    await scrollToRows(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  group('the band is inset the same on every face', () {
    // **Measured, because two of the four faces were not.** The loading and
    // error faces let `MxContentShell` pad their body while the band padded
    // itself, so the overview rendered 32dp a side there and 16 on the loaded
    // face — it snapped wider the moment the level answered, and narrower again
    // whenever a read failed. Nothing measured either face: the geometry suite
    // only ever pumps the loaded one.
    Future<void> expectBandGutter(WidgetTester tester) async {
      expect(
        tester.getRect(find.byType(ProgressStreakHeroWidget)).left,
        AppSpacing.lg,
      );
    }

    testWidgets('loaded', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: composed(levelWith(activeCards: 42)).repository,
      );
      await expectBandGutter(tester);
    });

    testWidgets('loading', (tester) async {
      final never = StreamController<DeckActivitySnapshot>.broadcast();
      addTearDown(never.close);
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository(
          initial: progressOverviewFixture(
            totals: const <int>[1, 1, 1, 1, 1, 1, 2],
            streakDays: 3,
          ),
          activity: (String? deckId) => never.stream,
        ),
      );
      await tester.pump();
      await expectBandGutter(tester);
    });

    testWidgets('empty', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository(
          initial: progressOverviewFixture(
            totals: const <int>[1, 1, 1, 1, 1, 1, 2],
            streakDays: 3,
          ),
          activity: (String? deckId) =>
              Stream<DeckActivitySnapshot>.value(emptyActivitySnapshot()),
        ),
      );
      await expectBandGutter(tester);
    });

    testWidgets('error', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository.failing(
          const DatabaseFailure(message: 'level read failed'),
        ),
      );
      await expectBandGutter(tester);
    });
  });

  testWidgets('the pinned strip is painted in the page colour, not the card '
      'colour', (tester) async {
    // `ColorScheme.surface` is what `MxCard` paints, and it was the first
    // choice here — measured against `scaffoldBackgroundColor` that is ΔL* 2.17
    // light and 6.38 dark, so the strip read as a square-cornered card and a
    // deck row scrolling under it dissolved into it instead of passing behind.
    await pumpProgressScreen(
      tester,
      repository: composed(levelWith(activeCards: 42)).repository,
    );

    final BuildContext context = tester.element(
      find.byType(ProgressRangeSelectorWidget),
    );
    final DecoratedBox box = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.byType(MxSubheaderBand),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );

    // Asserted against the **token**, not against the expression the widget
    // uses: `== Theme.of(context).scaffoldBackgroundColor` restates the code
    // under test and would hold whatever that resolved to. The second check is
    // the one that says the strip is not painted in the card's colour, which is
    // the mistake this replaced.
    expect(
      (box.decoration as BoxDecoration).color,
      AppSurfaceColors.backgroundLight,
    );
    expect(
      (box.decoration as BoxDecoration).color,
      isNot(Theme.of(context).colorScheme.surface),
      reason: 'the two differ, which is the whole point',
    );
  });

  testWidgets('a level emission leaves the overview alone', (tester) async {
    final parts = composed(levelWith(activeCards: 42));
    await pumpProgressScreen(tester, repository: parts.repository);

    parts.level.add(levelWith(activeCards: 43));
    await tester.pump();
    expect(find.byType(MxLoadingState), findsNothing, reason: 'rebuild frame');
    await tester.pump();

    // The header is still the same header, showing the same figure: the level
    // updating must not re-open the overview read, which is what a screen that
    // rebuilt the header from the level's `AsyncValue` would do.
    expect(find.text(english.progressTodayCardsLabel(2)), findsOneWidget);
    expect(find.byType(ProgressStreakHeroWidget), findsOneWidget);
    expect(parts.repository.subscriptionCount, 1);
  });
}
