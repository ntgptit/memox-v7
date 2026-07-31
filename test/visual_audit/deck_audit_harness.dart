import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../features/deck/presentation/support/fake_deck_repository.dart';
import 'screen_auditor.dart';

// What every deck audit scenario needs to stand a screen up, extracted from the
// companion test.
//
// **Beside `deck_audit_allowances.dart`, not under `screens/`.** MX-VIS-001
// requires exactly one `*_visual_audit_test.dart` per production screen and
// derives its path from the screen's; a second file in that tree invites the
// question of which one is the companion. This is a harness, so it lives with
// the other deck audit harness.
//
// It was extracted because the companion sat at 399 lines against the guard's
// 400 — one scenario, or one comment, from failing. Moving the setup out is what
// keeps that file a list of states rather than a list of states plus a fixture.

/// The production route table at [location], with the database faked out.
///
/// The router is per-call because `GoRouter` carries navigation history and the
/// harness builds one screen per theme; sharing one would let the light run
/// decide where the dark run starts.
Widget deckShellWith(FakeDeckRepository repository, {String? location}) {
  // No `initialLocation` for the root level: the default is already the deck
  // branch, and stating it trips `avoid_redundant_argument_values`, a lint this
  // project promotes to error.
  final router = location == null
      ? createAppRouter()
      : createAppRouter(initialLocation: location);
  addTearDown(router.dispose);

  return ProviderScope(
    overrides: [
      envConfigProvider.overrideWithValue(EnvConfig.development),
      deckRepositoryProvider.overrideWithValue(repository),
      // A fixed clock, so the due counts in the loaded states are identical on
      // every run.
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 7, 29, 12)),
    ],
    child: Router.withConfig(config: router),
  );
}

/// The shell parked inside a deck rather than on the root list.
Widget deckLevelWith(FakeDeckRepository repository) =>
    deckShellWith(repository, location: '/decks/deck-1');

/// Lets the pushed route finish laying out before the walk starts.
///
/// A level inside a deck is a *child* route, so mounting it puts two routes in
/// the branch Navigator and starts a page transition. The audit walks the render
/// tree, and a route still mid-insertion has boxes that have not been laid out —
/// walking one throws rather than reporting a colour. Settling first is not
/// hiding anything: the audit is about the screen at rest.
Future<void> settleDeckScreen(WidgetTester tester) => tester.pumpAndSettle();

/// A repository serving one deck and the children it should show.
FakeDeckRepository servingDeckLevel(
  DeckEntity deck, {
  List<DeckSummary> children = const <DeckSummary>[],
  List<DeckPathSegment> ancestors = const <DeckPathSegment>[],
}) => FakeDeckRepository(
  deckList: (_) => Stream<DeckListSnapshot>.value(
    DeckListSnapshot(
      ancestors: ancestors,
      parent: deck,
      decks: children,
      nextDueAt: null,
    ),
  ),
  allDecks: () => Stream<List<DeckEntity>>.value(<DeckEntity>[deck]),
);

/// The three things a state with an empty body has to name.
final List<AuditAnchor> deckAnchorsWithEmpty = <AuditAnchor>[
  AuditAnchor.type('deck_screen', DeckListScreen),
  AuditAnchor.type('empty_state', MxEmptyState),
  AuditAnchor.type('navigation_bar', MxNavigationBar),
];

/// The same, for a state whose body is a list rather than an empty state.
final List<AuditAnchor> deckPlainAnchors = <AuditAnchor>[
  AuditAnchor.type('deck_screen', DeckListScreen),
  AuditAnchor.type('navigation_bar', MxNavigationBar),
];
