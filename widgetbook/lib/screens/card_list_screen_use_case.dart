import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox_widgetbook/support/catalog_route_stub.dart';
import 'package:widgetbook/widgetbook.dart';

import 'card_list_catalog_repository.dart';

/// `CardListScreen` mounted whole, its one contract faked (UC-04, M4.11).
///
/// The last card screen to reach the catalog, and the Definition of Done in
/// `CLAUDE.md` asks for it because nothing else here shows the screen's
/// *composition*: the breadcrumb over the title, the search field beside the
/// filter pills, the "showing N of M" line, the selection bar taking over the
/// app bar, and the FAB sitting over the last row. The component playgrounds
/// each show one of those parts; only the real screen shows them competing for
/// the same width.
///
/// **The controls work.** The fake re-implements filtering, search, sort, the
/// tag filter and the four bulk writes, so the empty faces — a deck with no
/// cards, a filter that matches nothing, a search that matches nothing — are
/// reached by using the screen rather than by picking a scenario for each. Long
/// press a row to enter selection mode.
WidgetbookComponent cardListScreenComponent() {
  return WidgetbookComponent(
    name: 'CardListScreen',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final scenario = context.knobs.object.dropdown<CardListScenario>(
            label: 'scenario',
            options: CardListScenario.values,
            labelBuilder: (CardListScenario value) => value.label,
          );

          // Keyed by scenario so changing it rebuilds from scratch: the fake's
          // store is mutable — bulk actions really delete rows — and one
          // scenario's edits must not survive into the next.
          return _CardListDemo(
            key: ValueKey<Object>(scenario),
            scenario: scenario,
          );
        },
      ),
    ],
  );
}

class _CardListDemo extends StatefulWidget {
  const _CardListDemo({required this.scenario, super.key});

  final CardListScenario scenario;

  @override
  State<_CardListDemo> createState() => _CardListDemoState();
}

class _CardListDemoState extends State<_CardListDemo> {
  /// Every route the screen can navigate to, so no tap throws.
  ///
  /// The four destinations land on the shared [CatalogRouteStubPage]: each is
  /// a screen with its own contracts and its own use-case here, and re-faking
  /// them would make this entry quietly responsible for four others. What this
  /// router has to prove is that the *screen* routes correctly — that a row tap
  /// reaches detail rather than the editor (BR-246), and that Import pushes
  /// while the editor goes. The destination's own entry proves the rest.
  ///
  /// Held on the state: a router built in `build` would reset its stack every
  /// time the knobs panel rebuilds.
  late final GoRouter _router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/decks/:${RoutePathParams.deckId}/cards',
        name: RouteNames.cardList,
        builder: (context, state) => CardListScreen(
          deckId: state.pathParameters[RoutePathParams.deckId]!,
        ),
        routes: <RouteBase>[
          GoRoute(
            path: 'new',
            name: RouteNames.cardEditor,
            builder: (context, state) =>
                const CatalogRouteStubPage(routeName: 'Card editor · create'),
          ),
          GoRoute(
            path: 'import',
            name: RouteNames.cardImport,
            builder: (context, state) =>
                const CatalogRouteStubPage(routeName: 'Card import'),
          ),
          GoRoute(
            path: ':${RoutePathParams.cardId}',
            name: RouteNames.cardDetail,
            builder: (context, state) =>
                const CatalogRouteStubPage(routeName: 'Card detail'),
            routes: <RouteBase>[
              GoRoute(
                path: 'edit',
                name: RouteNames.cardEditorEdit,
                builder: (context, state) =>
                    const CatalogRouteStubPage(routeName: 'Card editor · edit'),
              ),
            ],
          ),
        ],
      ),
    ],
    initialLocation: '/decks/deck-1/cards',
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
        cardRepositoryProvider.overrideWithValue(
          CardListCatalogRepository(widget.scenario),
        ),
        // Pinned with the fake's own instant, so the due badges a row draws
        // agree with the schedule the fake handed it — and so a screenshot
        // taken next month still shows "in 4d".
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 8, 14, 9, 41)),
      ],
      child: Router<Object>.withConfig(config: _router),
    );
  }
}
