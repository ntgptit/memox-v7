import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/features/progress/di/progress_repository_provider.dart';
import 'package:memox/features/progress/domain/models/deck_activity_metrics_model.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/domain/models/deck_activity_snapshot_model.dart';
import 'package:memox/features/progress/domain/models/progress_path_segment_model.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';
import 'package:memox/features/progress/presentation/screens/progress_deck_screen.dart';
import 'package:widgetbook/widgetbook.dart';

/// `ProgressDeckScreen` mounted whole, with the repository contract faked.
///
/// The composition check the component playgrounds cannot do: a 2×2 metric grid
/// inside a card, inside a list, under a summary panel — where the failure modes
/// are a long deck path wrapping into the metrics and a five-digit count pushing
/// its own word off the cell. Both are knob-selectable below.
///
/// The use case carries its own mini `GoRouter` with both progress routes, so
/// tapping a row actually drills down inside the catalog frame.
WidgetbookComponent progressDeckScreenComponent() {
  return WidgetbookComponent(
    name: 'ProgressDeckScreen',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final scenario = context.knobs.object.dropdown<ProgressScenario>(
            label: 'scenario',
            options: ProgressScenario.values,
            labelBuilder: (ProgressScenario value) => value.label,
          );

          // Keyed by scenario so changing it rebuilds from scratch: the
          // router's stack and the fake's data belong to one scenario and must
          // not leak into the next.
          return _ProgressDemo(
            key: ValueKey<Object>(scenario),
            scenario: scenario,
          );
        },
      ),
    ],
  );
}

/// The states worth looking at, per the feature-slice checklist.
enum ProgressScenario {
  mixed('mixed activity'),
  allZero('nothing studied'),
  longPaths('long nested paths'),
  largeCounts('five-digit counts'),
  noDecks('no decks yet'),
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
  /// Both progress routes, so the row's `pushNamed` resolves. Held on the state
  /// — a router created in `build` would reset its stack on every rebuild the
  /// knobs panel triggers.
  late final GoRouter _router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: RouteNames.progress,
        builder: (BuildContext context, GoRouterState state) =>
            const ProgressDeckScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: ':deckId',
            name: RouteNames.progressDeck,
            builder: (BuildContext context, GoRouterState state) =>
                ProgressDeckScreen(
                  deckId: state.pathParameters[RoutePathParams.deckId],
                ),
          ),
        ],
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
/// states, it does not simulate a day rolling over.
class _CatalogProgressRepository implements ProgressRepository {
  _CatalogProgressRepository(this.scenario);

  final ProgressScenario scenario;

  @override
  Stream<DeckActivitySnapshot> watchDeckActivity({
    required String? deckId,
    required DateTime now,
    required Duration utcOffset,
  }) {
    if (scenario == ProgressScenario.error) {
      return Stream<DeckActivitySnapshot>.error(
        const DatabaseFailure(message: 'catalog demo failure'),
      );
    }

    final List<DeckActivity> decks = _decks(deckId);

    return Stream<DeckActivitySnapshot>.value(
      DeckActivitySnapshot(
        scopeDeckId: deckId,
        scopeName: deckId == null ? null : 'Deck $deckId',
        scopePath: const <ProgressPathSegment>[],
        decks: decks,
        scopeLast7Days: _total(decks, isMonth: false),
        scopeLast30Days: _total(decks, isMonth: true),
        nextDayBoundaryAt: DateTime.utc(2026, 8, 14),
      ),
    );
  }

  /// The scope total. Summed here — which production deliberately does not do,
  /// because active days do not add up — and that is acceptable in a catalog:
  /// these are illustrative figures, not a claim about a database.
  DeckActivityMetrics _total(
    List<DeckActivity> decks, {
    required bool isMonth,
  }) {
    if (decks.isEmpty) return DeckActivityMetrics.zero;

    return decks
        .map((DeckActivity d) => isMonth ? d.last30Days : d.last7Days)
        .reduce(
          (DeckActivityMetrics a, DeckActivityMetrics b) => DeckActivityMetrics(
            activeCardCount: a.activeCardCount + b.activeCardCount,
            activeDayCount: a.activeDayCount > b.activeDayCount
                ? a.activeDayCount
                : b.activeDayCount,
            learningCardDayCount:
                a.learningCardDayCount + b.learningCardDayCount,
            reviewingCardDayCount:
                a.reviewingCardDayCount + b.reviewingCardDayCount,
          ),
        );
  }

  List<DeckActivity> _decks(String? deckId) => switch (scenario) {
    ProgressScenario.noDecks ||
    ProgressScenario.error => const <DeckActivity>[],
    ProgressScenario.allZero => <DeckActivity>[
      _deck('r1', 'Spanish', 0, 0, 0, 0),
      _deck('r2', 'Tiếng Nhật', 0, 0, 0, 0),
    ],
    ProgressScenario.longPaths => <DeckActivity>[
      _deck(
        'r1',
        'Động từ bất quy tắc nhóm hai',
        18,
        6,
        7,
        24,
        path: const <ProgressPathSegment>[
          ProgressPathSegment(id: 'a', name: 'Tiếng Nhật tổng hợp'),
          ProgressPathSegment(id: 'b', name: 'Ngữ pháp trình độ trung cấp'),
          ProgressPathSegment(id: 'c', name: 'Bài 12 — thể khả năng'),
        ],
      ),
      _deck('r2', 'Kanji', 4, 2, 0, 5),
    ],
    ProgressScenario.largeCounts => <DeckActivity>[
      _deck('r1', 'Everything', 24680, 30, 13579, 98765),
      _deck('r2', 'Archive', 1024, 28, 0, 4096),
    ],
    ProgressScenario.mixed => <DeckActivity>[
      _deck('r1', 'Spanish', 42, 6, 12, 60),
      _deck('r2', 'Tiếng Nhật', 17, 4, 9, 21),
      _deck('r3', 'Idle deck', 0, 0, 0, 0),
    ],
  };

  DeckActivity _deck(
    String id,
    String name,
    int cards,
    int days,
    int learning,
    int reviewing, {
    List<ProgressPathSegment> path = const <ProgressPathSegment>[],
  }) => DeckActivity(
    deckId: id,
    name: name,
    path: path,
    last7Days: DeckActivityMetrics(
      activeCardCount: cards,
      activeDayCount: days,
      learningCardDayCount: learning,
      reviewingCardDayCount: reviewing,
    ),
    // Roughly three times the week, so switching the selector visibly changes
    // every figure rather than looking like a control that does nothing.
    last30Days: DeckActivityMetrics(
      activeCardCount: cards * 3,
      activeDayCount: days * 4,
      learningCardDayCount: learning * 3,
      reviewingCardDayCount: reviewing * 3,
    ),
  );
}
