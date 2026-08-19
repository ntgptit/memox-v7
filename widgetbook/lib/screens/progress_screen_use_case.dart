import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/progress/di/progress_repository_provider.dart';
import 'package:memox/features/progress/domain/models/progress_activity_day_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';
import 'package:memox/features/progress/presentation/screens/progress_deck_screen.dart';
import 'package:memox/features/progress/presentation/screens/progress_screen.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:memox/features/progress/domain/models/deck_activity_metrics_model.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/domain/models/deck_activity_snapshot_model.dart';
import 'package:memox/features/progress/domain/models/progress_path_segment_model.dart';

/// `ProgressScreen` mounted whole, with the repository contract faked.
///
/// The catalog's job here is the composition the section playgrounds cannot
/// show: three cards sharing one content column, the chart's shared bar
/// baseline, and how all of it behaves at a 2.0 text scale on a 320 viewport —
/// the axes the addons drive.
///
/// **The clock is pinned.** Every scenario is built around one fixed instant, so
/// a screenshot taken today and one taken next week are the same screenshot.
/// That is only possible because nothing under `lib/features/` reads the wall
/// clock (AD-16).
WidgetbookComponent progressScreenComponent() {
  return WidgetbookComponent(
    name: 'ProgressScreen',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final scenario = context.knobs.object.dropdown<ProgressScenario>(
            label: 'scenario',
            options: ProgressScenario.values,
            labelBuilder: (ProgressScenario value) => value.label,
          );

          return _ProgressDemo(
            key: ValueKey<Object>(scenario),
            scenario: scenario,
          );
        },
      ),
    ],
  );
}

/// The faces of the state matrix (S-a…S-e of the wireframe), plus the two
/// extremes that stress the layout rather than the logic.
enum ProgressScenario {
  normal('a mixed week'),
  todayZeroStreakHeld('today 0, streak held from yesterday'),
  longStreak('300-day streak, three-digit days'),
  singleDay('first day, one card'),
  emptyLifetime('never studied'),
  loading('loading'),
  error('read fails');

  const ProgressScenario(this.label);

  final String label;
}

class _ProgressDemo extends StatefulWidget {
  const _ProgressDemo({required this.scenario, super.key});

  final ProgressScenario scenario;

  @override
  State<_ProgressDemo> createState() => _ProgressDemoState();
}

class _ProgressDemoState extends State<_ProgressDemo> {
  /// The Progress route plus the Study route its empty-state action navigates
  /// to, so the CTA resolves inside the catalog instead of throwing.
  late final GoRouter _router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: RouteNames.progress,
        builder: (context, state) => const ProgressScreen(),
        routes: <RouteBase>[
          // The drill-down a deck row pushes. It only became reachable when
          // this use case started catalogueing the composed screen: with an
          // empty level there was no row to press, and without this route the
          // first press threw `GoError: no routes for location`.
          GoRoute(
            path: ':deckId',
            name: RouteNames.progressDeck,
            builder: (context, state) => ProgressDeckScreen(
              deckId: state.pathParameters[RoutePathParams.deckId],
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/study',
        name: RouteNames.study,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Study branch'))),
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => _CatalogProgressRepository.now),
        utcOffsetProvider.overrideWithValue(() => Duration.zero),
        progressRepositoryProvider.overrideWithValue(
          _CatalogProgressRepository(widget.scenario),
        ),
      ],
      child: Router<Object>.withConfig(config: _router),
    );
  }
}

/// Enough of [ProgressRepository] to drive the screen.
///
/// Deterministic per scenario, and the stream never re-emits: the catalog shows
/// states, it does not simulate live refresh or a midnight rollover — both of
/// those are behaviour over time, which belongs to the controller tests.
class _CatalogProgressRepository implements ProgressRepository {
  _CatalogProgressRepository(this.scenario);

  final ProgressScenario scenario;

  /// Wednesday, so the seven-day window shows a full spread of weekday labels
  /// rather than a run that starts and ends on the same name.
  static final DateTime now = DateTime.utc(2026, 8, 12, 9, 30);

  static final DateTime _today = DateTime.utc(2026, 8, 12);

  /// The level below the overview header.
  ///
  /// **Populated, because `/progress` is one screen.** This started as an empty
  /// level on the argument that the use case is about the three overview
  /// sections — and the result was a catalogue entry for a surface the app does
  /// not have: an empty top level drops the pinned range selector, the totals
  /// panel and the list, so the one place a reviewer could look at the composed
  /// screen showed three cards and an empty state. The deck level keeps its own
  /// use case for its own scenarios; this one shows what the tab opens on.
  @override
  Stream<DeckActivitySnapshot> watchDeckActivity({
    required String? deckId,
    required DateTime now,
    required Duration utcOffset,
  }) => Stream<DeckActivitySnapshot>.value(
    DeckActivitySnapshot(
      scopeDeckId: deckId,
      scopeName: null,
      scopePath: const <ProgressPathSegment>[],
      // No `emptyLifetime` branch: that scenario never reaches this read at
      // all, because `ProgressScreen` renders the whole-screen empty face
      // instead of building the level. A branch for it would be a case nobody
      // can see, which is worse than none.
      decks: _catalogDecks,
      scopeLast7Days: const DeckActivityMetrics(
        activeCardCount: 45,
        activeDayCount: 6,
        learningCardDayCount: 12,
        reviewingCardDayCount: 60,
      ),
      scopeLast30Days: const DeckActivityMetrics(
        activeCardCount: 128,
        activeDayCount: 21,
        learningCardDayCount: 40,
        reviewingCardDayCount: 210,
      ),
      nextDayBoundaryAt: _today.add(const Duration(days: 1)),
    ),
  );

  /// Two rows: one that has been studied and one that has not, which is the
  /// pair BR-187 orders and the only pair worth catalogueing here — the deck
  /// level's own use case carries the long-name and all-zero scenarios.
  static const List<DeckActivity> _catalogDecks = <DeckActivity>[
    DeckActivity(
      deckId: 'r1',
      name: 'Spanish',
      path: <ProgressPathSegment>[],
      last7Days: DeckActivityMetrics(
        activeCardCount: 42,
        activeDayCount: 6,
        learningCardDayCount: 12,
        reviewingCardDayCount: 60,
      ),
      last30Days: DeckActivityMetrics(
        activeCardCount: 120,
        activeDayCount: 21,
        learningCardDayCount: 40,
        reviewingCardDayCount: 210,
      ),
    ),
    DeckActivity(
      deckId: 'r2',
      name: 'Idle deck',
      path: <ProgressPathSegment>[],
      last7Days: DeckActivityMetrics.zero,
      last30Days: DeckActivityMetrics.zero,
    ),
  ];

  @override
  Stream<ProgressOverview> watchProgressOverview({
    required DateTime now,
    required Duration utcOffset,
  }) {
    if (scenario == ProgressScenario.loading) {
      return const Stream<ProgressOverview>.empty();
    }
    if (scenario == ProgressScenario.error) {
      return Stream<ProgressOverview>.error(
        const DatabaseFailure(message: 'catalog demo failure'),
      );
    }

    return Stream<ProgressOverview>.value(
      ProgressOverview(
        lastSevenDays: _window(),
        currentStreakDays: _streak(),
        hasLifetimeActivity: scenario != ProgressScenario.emptyLifetime,
        nextLocalMidnight: _today.add(const Duration(days: 1)),
      ),
    );
  }

  int _streak() => switch (scenario) {
    ProgressScenario.normal => 5,
    ProgressScenario.todayZeroStreakHeld => 4,
    ProgressScenario.longStreak => 300,
    ProgressScenario.singleDay => 1,
    _ => 0,
  };

  /// Seven days, oldest first, today last — the shape BR-196 fixes and the
  /// screen relies on.
  List<ProgressActivityDay> _window() {
    final List<int> totals = switch (scenario) {
      ProgressScenario.normal => <int>[12, 6, 0, 9, 3, 14, 8],
      ProgressScenario.todayZeroStreakHeld => <int>[4, 7, 5, 0, 6, 11, 0],
      ProgressScenario.longStreak => <int>[128, 97, 143, 88, 156, 102, 119],
      ProgressScenario.singleDay => <int>[0, 0, 0, 0, 0, 0, 1],
      _ => <int>[0, 0, 0, 0, 0, 0, 0],
    };

    return <ProgressActivityDay>[
      for (final (int index, int total) in totals.indexed)
        ProgressActivityDay(
          localDate: _today.subtract(Duration(days: totals.length - 1 - index)),
          totalCards: total,
          // A partition, roughly a third learning — enough for the two rows of
          // the Today panel to hold different numbers.
          learningCards: total ~/ 3,
        ),
    ];
  }
}
