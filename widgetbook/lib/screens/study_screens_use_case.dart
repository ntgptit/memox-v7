import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/study/di/study_home_repository_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/features/study/presentation/screens/study_options_screen.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_direction_chooser_widget.dart';
import 'package:widgetbook/widgetbook.dart';

import 'study_catalog_repository.dart';
import '../support/catalog_route_stub.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/study/domain/failures/study_refusal_failure.dart';
import 'package:memox/features/study/domain/models/study_direction_model.dart';

/// The Study screens, mounted whole against the catalog's own repository.
///
/// **They were the catalog's outstanding debt** — M5.7 added two screens and
/// M5.11 a third, and none of them were registered, because the app's test
/// doubles live under `test/` and a second package cannot import them. The debt
/// closes with `StudyCatalogRepository`, which is the catalog's own.
///
/// The clock and the timezone are pinned for the same reason the repository is:
/// `domain/` takes both as inputs (AD-06, AD-16), so a catalog that left them
/// real would show a different screen every day it was opened.
final DateTime _catalogNow = DateTime.utc(2026, 8, 8, 2);

/// The one deck every Study use-case is scoped to.
const String _catalogDeckId = 'catalog-deck';

/// `/study/catalog-deck` — the entry screen's location inside the Study branch.
const String _catalogEntryLocation = '${RoutePaths.study}/$_catalogDeckId';

List<WidgetbookComponent> studyScreenComponents() => <WidgetbookComponent>[
  // First, because it is the tab's own screen: the Study branch opens here and
  // every other Study screen is reached through it (UC-14).
  //
  // **The two that navigate by name are mounted through a router**, at the
  // location the app opens them at. Mounted bare, `goNamed` and `pushNamed`
  // find no `GoRouter` above them and throw — so Study Home's deck rows and
  // the entry screen's options action were dead controls in the catalog, which
  // is the one place a reviewer is expected to press them. The routes below
  // are the Study branch's own, named from `RouteNames` and pathed from
  // `RoutePaths`, so this is a mirror of the app's table rather than a second
  // one that can drift from it.
  _screen(
    'StudyHomeScreen',
    (scenario) => const _StudyRouter(location: RoutePaths.study),
  ),
  _screen(
    'StudyEntryScreen',
    (scenario) => const _StudyRouter(location: _catalogEntryLocation),
  ),
  _screen(
    'StudySessionScreen',
    (scenario) => StudySessionScreen(
      deckId: _catalogDeckId,
      kind: scenario.isReview
          ? StudySessionKind.reviewing
          : StudySessionKind.learning,
      reviewMode: scenario.isReview ? StudyMode.selfAssess : null,
      direction: scenario.direction,
    ),
  ),
  _screen(
    'StudyOptionsScreen',
    (scenario) => const StudyOptionsScreen(deckId: _catalogDeckId),
  ),

  // **The one overlay in this list, and it earns the exception.** The other
  // Study sheets are a fixed list of choices; this one has three states of its
  // own — initial, submitting, and a refusal that keeps the selection — and the
  // middle two are unreachable from the screen entries above, because the
  // catalog's repository never fails. The dropdown drives them directly.
  _screen(
    'StudyDirectionChooser',
    (scenario) => _DirectionChooserDemo(scenario: scenario),
  ),
];

/// The direction sheet on its own, with its three states on the scenario knob.
///
/// Mounted flat rather than inside a real `showModalBottomSheet`: a catalog page
/// is not a route, and the sheet's own `SafeArea` + scroll behaviour is what a
/// reviewer needs to look at. **The chrome is the theme's, not a stand-in** —
/// `bottomSheetTheme` gives the real sheet `surface` and its top radius, and the
/// demo used `surfaceContainerLow` — a different colour in dark, and the one the
/// selected radio glyph happens to sit on, so the catalogue was showing the
/// wrong ground under the exact pixel that turned out to be 2.45:1.
///
/// The drag handle is **not** here: `showDragHandle: true` is a `BottomSheet`
/// property rather than a `BottomSheetThemeData` one, so a flat mount cannot
/// inherit it. The ~24dp strip it occupies is missing from the top of this
/// page, which is worth knowing if you came to look at the sheet's top spacing.
class _DirectionChooserDemo extends StatelessWidget {
  const _DirectionChooserDemo({required this.scenario});

  /// **Read, since the knob is there.** The first version took the parameter
  /// and ignored it, and hard-coded a future that never resolves — so the
  /// refusal state this entry exists to show could not be reached at all,
  /// while the doc above said the dropdown drove it.
  final StudyCatalogScenario scenario;

  Future<Object?> _submit(
    StudySessionDirection direction,
  ) => switch (scenario) {
    // The other refusal: one a retry can genuinely fix, so the CTA stays live
    // under it. Reachable on the long-content scenario for no reason except
    // that a scenario had to carry it.
    StudyCatalogScenario.longContent => Future<Object?>.value(
      const ConflictFailure(
        message: 'catalog: this deck no longer uses sm2',
        reason: StudyRefusalReason.modeNotSupportedByScheduler,
      ),
    ),
    // Nothing due: the refusal that keeps the selection and disables the CTA.
    StudyCatalogScenario.nothingDue ||
    StudyCatalogScenario.nothingLeft => Future<Object?>.value(
      const ConflictFailure(
        message: 'catalog: nothing due to review',
        reason: StudyRefusalReason.nothingDueToReview,
      ),
    ),
    // Anything else: a submit that never lands, so the busy state holds still
    // for as long as somebody wants to look at it.
    _ => Completer<Object?>().future,
  };

  @override
  Widget build(BuildContext context) {
    final BottomSheetThemeData sheet = Theme.of(context).bottomSheetTheme;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: sheet.backgroundColor ?? Theme.of(context).colorScheme.surface,
        shape: sheet.shape,
        child: StudyDirectionChooserWidget(onSubmit: _submit),
      ),
    );
  }
}

/// One screen, with the scenario dropdown every Study use-case shares.
WidgetbookComponent _screen(
  String name,
  Widget Function(StudyCatalogScenario scenario) build,
) => WidgetbookComponent(
  name: name,
  useCases: <WidgetbookUseCase>[
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) {
        final scenario = context.knobs.object.dropdown<StudyCatalogScenario>(
          label: 'scenario',
          options: StudyCatalogScenario.values,
          labelBuilder: (StudyCatalogScenario value) => value.label,
        );

        // Keyed by scenario so switching it rebuilds from scratch: a study
        // session screen opens its session in a post-frame callback, and a tree
        // that survived the switch would still hold the previous scenario's.
        return _StudyDemo(
          key: ValueKey<Object>(scenario),
          scenario: scenario,
          child: build(scenario),
        );
      },
    ),
  ],
);

/// The Study branch's routes, so the screens' `goNamed` and `pushNamed` land.
///
/// Held on the state rather than built in `build`: a router rebuilt on every
/// knob change would drop whatever the reviewer had navigated to, which is the
/// one thing this widget exists to make possible. The scenario dropdown still
/// resets it, because `_StudyDemo` is keyed by scenario — a router holding the
/// previous scenario's stack is not a state the app can be in.
///
/// Every name a Study screen can reach is registered. The two that leave the
/// branch — the library and the starter catalogue — land on
/// [CatalogRouteStubPage]: they are other features' screens with their own
/// entries and their own fakes, and a router that mounted them for real would
/// be a second app rather than a catalogue.
class _StudyRouter extends StatefulWidget {
  const _StudyRouter({required this.location});

  /// Where this use-case opens — the same location the app would be at.
  final String location;

  @override
  State<_StudyRouter> createState() => _StudyRouterState();
}

class _StudyRouterState extends State<_StudyRouter> {
  late final GoRouter _router = GoRouter(
    initialLocation: widget.location,
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.decks,
        name: RouteNames.decks,
        builder: (BuildContext context, GoRouterState state) =>
            const CatalogRouteStubPage(routeName: 'Library'),
        routes: <RouteBase>[
          GoRoute(
            path: RoutePaths.starterLibraryRelative,
            name: RouteNames.starterLibrary,
            builder: (BuildContext context, GoRouterState state) =>
                const CatalogRouteStubPage(routeName: 'Starter library'),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.study,
        name: RouteNames.study,
        builder: (BuildContext context, GoRouterState state) =>
            const StudyHomeScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: RoutePaths.studyDeckRelative,
            name: RouteNames.studyDeck,
            builder: (BuildContext context, GoRouterState state) =>
                StudyEntryScreen(
                  deckId: state.pathParameters[RoutePathParams.deckId]!,
                  // The Study branch's options route, because this router is
                  // the Study branch. The screen is mounted twice in the app
                  // and the branch is the route's fact, not the screen's.
                  optionsRouteName: RouteNames.studyDeckOptions,
                ),
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.studyOptionsRelative,
                name: RouteNames.studyDeckOptions,
                builder: (BuildContext context, GoRouterState state) =>
                    StudyOptionsScreen(
                      deckId: state.pathParameters[RoutePathParams.deckId]!,
                    ),
              ),
            ],
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
  Widget build(BuildContext context) =>
      Router<Object>.withConfig(config: _router);
}

class _StudyDemo extends StatelessWidget {
  const _StudyDemo({required this.scenario, required this.child, super.key});

  final StudyCatalogScenario scenario;
  final Widget child;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      studyRepositoryProvider.overrideWithValue(
        StudyCatalogRepository(scenario),
      ),
      studyHomeRepositoryProvider.overrideWithValue(
        StudyHomeCatalogRepository(scenario),
      ),
      clockProvider.overrideWithValue(() => _catalogNow),
      utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
    ],
    child: child,
  );
}
