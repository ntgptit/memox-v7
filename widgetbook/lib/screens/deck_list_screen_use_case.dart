import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_impact_model.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:widgetbook/widgetbook.dart';

/// `DeckListScreen` mounted whole, with the repository contract faked.
///
/// This is the composition check the component playgrounds cannot do: the
/// toolbar next to the list, a counter wrapping beside a trailing action, the
/// FAB inset — visible only with the real screen and controllable data. The
/// use-case carries its own mini `GoRouter` with the two deck routes, so
/// tapping a row **actually drills down** inside the catalog frame.
WidgetbookComponent deckListScreenComponent() {
  return WidgetbookComponent(
    name: 'DeckListScreen',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final scenario = context.knobs.object.dropdown<DeckListScenario>(
            label: 'scenario',
            options: DeckListScenario.values,
            labelBuilder: (DeckListScenario value) => value.label,
          );

          // Keyed by scenario so changing it rebuilds the demo from scratch:
          // the router's navigation stack and the fake's data belong to one
          // scenario and must not leak into the next.
          return _DeckListDemo(
            key: ValueKey<Object>(scenario),
            scenario: scenario,
          );
        },
      ),
    ],
  );
}

/// The states worth looking at, per the feature-slice checklist: empty, a few
/// items, long Vietnamese names, a big list, the due-filter edge, and error.
enum DeckListScenario {
  fewRoots('a few root decks'),
  longNames('long Vietnamese names'),
  manyDecks('25 decks'),
  overdue('mixed workload with backlog'),
  overdueOnly('overdue only'),
  dueTodayOnly('due today only'),
  newOnly('new cards only'),
  nothingDue('nothing due'),
  empty('no decks yet'),
  error('read fails');

  const DeckListScenario(this.label);

  final String label;
}

class _DeckListDemo extends StatefulWidget {
  const _DeckListDemo({required this.scenario, super.key});

  final DeckListScenario scenario;

  @override
  State<_DeckListDemo> createState() => _DeckListDemoState();
}

class _DeckListDemoState extends State<_DeckListDemo> {
  /// Both deck routes, so `goNamed` calls inside the screen resolve. Held on
  /// the state — a router created in `build` would reset its stack on every
  /// rebuild the knobs panel triggers.
  late final GoRouter _router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: RouteNames.decks,
        builder: (context, state) => const DeckListScreen(),
      ),
      GoRoute(
        path: '/decks/:deckId',
        name: RouteNames.deckDetail,
        builder: (context, state) => DeckListScreen(
          parentDeckId: state.pathParameters[RoutePathParams.deckId],
        ),
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
        deckRepositoryProvider.overrideWithValue(
          _CatalogDeckRepository(widget.scenario),
        ),
      ],
      child: Router<Object>.withConfig(config: _router),
    );
  }
}

/// Enough of [DeckRepository] to drive the list screen.
///
/// Reads are deterministic per scenario; writes succeed as no-ops so the
/// create/rename forms can be opened and submitted without wiring a database
/// into the catalog. The stream never re-emits — the catalog shows states, it
/// does not simulate a sync.
class _CatalogDeckRepository implements DeckRepository {
  _CatalogDeckRepository(this.scenario);

  final DeckListScenario scenario;

  static final DateTime _t0 = DateTime.utc(2026);

  @override
  Stream<DeckListSnapshot> watchDeckList({
    required String? parentDeckId,
    required DateTime now,
    required Duration utcOffset,
  }) {
    if (scenario == DeckListScenario.error) {
      return Stream<DeckListSnapshot>.error(
        const DatabaseFailure(message: 'catalog demo failure'),
      );
    }

    if (parentDeckId == null) {
      return Stream<DeckListSnapshot>.value(
        DeckListSnapshot(
          parent: null,
          decks: _roots(),
          ancestors: const <DeckPathSegment>[],
          nextDueAt: null,
          nextOverdueTickAt: null,
        ),
      );
    }

    final parent = _deckById(parentDeckId);

    return Stream<DeckListSnapshot>.value(
      DeckListSnapshot(
        parent: parent,
        decks: _childrenOf(parent),
        ancestors: _ancestorsOf(parentDeckId),
        nextDueAt: null,
        nextOverdueTickAt: null,
      ),
    );
  }

  /// Root first, excluding the deck being looked inside — the same contract as
  /// the real read. Recovered from the synthetic id chain: `r2-c3-c1` has
  /// ancestors `r2` and `r2-c3`.
  List<DeckPathSegment> _ancestorsOf(String parentDeckId) {
    final segments = parentDeckId.split('-');
    final ancestors = <DeckPathSegment>[];
    var prefix = '';
    for (final segment in segments.take(segments.length - 1)) {
      prefix = prefix.isEmpty ? segment : '$prefix-$segment';
      final deck = _deckById(prefix);
      ancestors.add(DeckPathSegment(id: deck.id, name: deck.name));
    }

    return ancestors;
  }

  List<DeckSummary> _roots() {
    switch (scenario) {
      case DeckListScenario.empty:
        return const <DeckSummary>[];
      case DeckListScenario.manyDecks:
        return <DeckSummary>[
          for (var i = 1; i <= 25; i++)
            _summary(
              _root('r$i', 'Deck $i'),
              total: 20 + i,
              due: i.isEven ? 0 : i,
            ),
        ];
      case DeckListScenario.longNames:
        return <DeckSummary>[
          _summary(
            _root(
              'r1',
              'Bộ từ vựng học thuật dành cho kỳ thi đánh giá năng lực '
                  'chuyên sâu bậc sau đại học 2026',
            ),
            total: 480,
            due: 37,
          ),
          _summary(
            _root(
              'r2',
              'Thành ngữ và tục ngữ thường gặp trong giao tiếp công sở '
                  'và thư tín thương mại',
              scheduler: SchedulerType.sm2,
            ),
            total: 96,
            due: 0,
          ),
        ];
      case DeckListScenario.nothingDue:
        return <DeckSummary>[
          _summary(
            _root('r1', 'IELTS Academic'),
            total: 120,
            due: 0,
            learned: 120,
          ),
          _summary(
            _root('r2', 'Kanji N3', scheduler: SchedulerType.sm2),
            total: 300,
            due: 0,
            learned: 300,
          ),
        ];
      // The hero's overdue state (BR-161): the summary above the list carries
      // the missed calendar and the +7d badge for the level's oldest backlog.
      case DeckListScenario.overdue:
        return <DeckSummary>[
          _summary(
            _root('r1', 'Academic Word List'),
            total: 570,
            due: 12,
            newCards: 46,
            overdueCards: 8,
            overdueDays: 7,
          ),
          _summary(
            _root('r2', 'Kanji N3', scheduler: SchedulerType.sm2),
            total: 300,
            due: 3,
          ),
        ];
      // Backlog with nothing else: Overdue is the only non-zero metric.
      case DeckListScenario.overdueOnly:
        return <DeckSummary>[
          _summary(
            _root('r1', 'Academic Word List'),
            total: 570,
            due: 9,
            overdueCards: 9,
            overdueDays: 12,
          ),
        ];
      // Today's reviews only: the middle metric carries the headline.
      case DeckListScenario.dueTodayOnly:
        return <DeckSummary>[
          _summary(_root('r1', 'IELTS Academic'), total: 120, due: 6),
        ];
      // New promoted to the focal point: nothing due, work still waiting.
      case DeckListScenario.newOnly:
        return <DeckSummary>[
          _summary(
            _root('r1', 'Korean vocabulary'),
            total: 20,
            due: 0,
            newCards: 20,
            learned: 0,
          ),
        ];
      case DeckListScenario.fewRoots:
      case DeckListScenario.error:
        return <DeckSummary>[
          _summary(
            _root('r1', 'IELTS Academic'),
            total: 120,
            due: 8,
            newCards: 14,
          ),
          _summary(
            _root('r2', 'Kanji N3', scheduler: SchedulerType.sm2),
            total: 300,
            due: 0,
          ),
          _summary(_root('r3', 'Từ vựng chuyên ngành'), total: 45, due: 12),
          _summary(
            _root('r4', 'Idioms', scheduler: SchedulerType.sm2),
            total: 32,
            due: 3,
          ),
        ];
    }
  }

  /// Children are synthesised per parent: one `card` deck (BR-63 shows its
  /// notice when opened), one still-`unset`, one nested `deck`.
  ///
  /// The summary's scheduler is **resolved through the root** (BR-06), exactly
  /// as the real read does it — a sub-deck's own scheduler columns are null,
  /// and a fake that fell back to a constant here would show `eight_box` rows
  /// inside an `sm2` tree.
  List<DeckSummary> _childrenOf(DeckEntity parent) {
    if (parent.contentType != DeckContentType.deck) {
      return const <DeckSummary>[];
    }

    final rootScheduler =
        _deckById(parent.rootDeckId).schedulerType ?? SchedulerType.eightBox;

    return <DeckSummary>[
      _summary(
        _child(
          '${parent.id}-c1',
          'Unit 1 · Reading',
          parent,
          contentType: DeckContentType.card,
        ),
        total: 40,
        due: 5,
        scheduler: rootScheduler,
      ),
      _summary(
        _child(
          '${parent.id}-c2',
          'Unit 2 · Listening',
          parent,
          contentType: DeckContentType.unset,
        ),
        total: 0,
        due: 0,
        scheduler: rootScheduler,
      ),
      _summary(
        _child('${parent.id}-c3', 'Grammar', parent),
        total: 66,
        due: 2,
        scheduler: rootScheduler,
      ),
    ];
  }

  /// Rebuilds the entity a level was reached through. Ids are synthetic
  /// (`r2`, `r2-c1`, `r2-c1-c3`, …), so the shape is recoverable from the id.
  DeckEntity _deckById(String id) {
    final rootId = id.split('-').first;
    final root = _roots()
        .map((DeckSummary summary) => summary.deck)
        .firstWhere(
          (DeckEntity deck) => deck.id == rootId,
          orElse: () => _root(rootId, 'Deck $rootId'),
        );
    if (id == rootId) return root;

    var parent = root;
    var prefix = rootId;
    for (final segment in id.split('-').skip(1)) {
      prefix = '$prefix-$segment';
      final children = _childrenOf(parent).map((s) => s.deck);
      parent = children.firstWhere(
        (DeckEntity deck) => deck.id == prefix,
        orElse: () => _child(prefix, 'Deck $prefix', parent),
      );
    }

    return parent;
  }

  DeckEntity _root(
    String id,
    String name, {
    SchedulerType scheduler = SchedulerType.eightBox,
  }) {
    return DeckEntity(
      id: id,
      name: name,
      parentDeckId: null,
      rootDeckId: id,
      contentType: DeckContentType.deck,
      schedulerType: scheduler,
      schedulerGeneration: 1,
      firstAnsweredAt: null,
      createdAt: _t0,
      updatedAt: _t0,
    );
  }

  DeckEntity _child(
    String id,
    String name,
    DeckEntity parent, {
    DeckContentType contentType = DeckContentType.deck,
  }) {
    return DeckEntity(
      id: id,
      name: name,
      parentDeckId: parent.id,
      rootDeckId: parent.rootDeckId,
      contentType: contentType,
      schedulerType: null,
      schedulerGeneration: null,
      firstAnsweredAt: null,
      createdAt: _t0,
      updatedAt: _t0,
    );
  }

  DeckSummary _summary(
    DeckEntity deck, {
    required int total,
    required int due,
    int newCards = 0,
    int overdueCards = 0,
    int overdueDays = 0,
    int? learned,
    int subDecks = 0,
    SchedulerType? scheduler,
  }) {
    return DeckSummary(
      deck: deck,
      totalCardCount: total,
      newCardCount: newCards,
      dueCardCount: due,
      overdueCardCount: overdueCards,
      overdueDayCount: overdueDays,
      // Two thirds by default rather than zero or full: a catalog whose bars are
      // all empty shows the component's least interesting state, and one whose
      // bars are all complete shows only the success colour. A caller that cares
      // about either end passes it.
      learnedCardCount: learned ?? (total * 2) ~/ 3,
      subDeckCount: subDecks,
      schedulerType: scheduler ?? deck.schedulerType ?? SchedulerType.eightBox,
    );
  }

  // --- Writes: succeed as no-ops so the forms can be exercised. ---

  @override
  Future<DeckEntity> createRootDeck({
    required DeckName name,
    required SchedulerType schedulerType,
  }) async {
    return _root('r-created', name.value, scheduler: schedulerType);
  }

  @override
  Future<DeckEntity> createSubDeck({
    required DeckName name,
    required String parentDeckId,
  }) async {
    return _child('$parentDeckId-created', name.value, _deckById(parentDeckId));
  }

  @override
  Future<void> renameDeck({
    required String deckId,
    required DeckName name,
  }) async {}

  @override
  Future<DeckDeletionImpact> getDeletionImpact(String deckId) async {
    return const DeckDeletionImpact(descendantDeckCount: 2, cardCount: 11);
  }

  @override
  Future<void> deleteDeck(String deckId) async {}

  @override
  Future<void> resetContentType(String deckId) async {}

  @override
  Future<void> resetLearningProgress({
    required String rootDeckId,
    required SchedulerType schedulerType,
  }) async {}

  @override
  Future<void> changeUnlockedScheduler({
    required String rootDeckId,
    required SchedulerType schedulerType,
  }) async {}

  @override
  Future<void> moveDeck({
    required String deckId,
    required String targetParentDeckId,
  }) async {}

  // --- Reads the list screen never issues. ---

  @override
  Stream<List<DeckEntity>> watchRootDecks() =>
      const Stream<List<DeckEntity>>.empty();

  @override
  Stream<List<DeckEntity>> watchAllDecks() =>
      const Stream<List<DeckEntity>>.empty();

  @override
  Stream<List<DeckEntity>> watchDeckTree(String rootDeckId) =>
      const Stream<List<DeckEntity>>.empty();
}
