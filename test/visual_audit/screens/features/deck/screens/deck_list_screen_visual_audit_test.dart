@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../../../../../features/deck/presentation/support/fake_deck_repository.dart';
import '../../../../audit_allowance.dart';
import '../../../../deck_audit_allowances.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';

/// Strict visual audit for `DeckListScreen`, at both levels.
///
/// Companion of `lib/features/deck/presentation/screens/deck_list_screen.dart`,
/// at the mirrored path. `MX-VIS-001` checks that this file exists, imports that
/// screen, and calls the strict helper — a file that merely sits at the right
/// path proves nothing.
///
/// **One companion for what used to be two**, because there is now one screen.
/// The states below are still eight, and that is the honest number: the level and
/// the parent's content type decide which body is on screen, and an `unset` deck
/// and a `card` deck offer different actions (BR-61 vs BR-63), so auditing one
/// would leave the other's colours unread.
///
/// **Audited through the real router, not as a bare screen.** Since M4.10a the
/// deck list is never seen on its own: it is always inside the navigation shell,
/// with the bottom bar under it. `Router.withConfig` mounts the production route
/// table inside the harness's own `MaterialApp`, so the shell, the branch and the
/// bar are the real ones while the theme under test stays the harness's.
///
/// Loading is deliberately absent from both levels: `CircularProgressIndicator`
/// is mid-animation at any pump, so its paint is not a stable subject — it is
/// covered by the widget tests instead.
///
/// The allowance counts differ per state because the number of icon buttons on
/// screen differs, and every count is exact: `expectedMatches` fails when the
/// number moves at all, in either direction.
void main() {
  /// The production route table at [location], with the database faked out.
  ///
  /// The router is per-call because `GoRouter` carries navigation history and the
  /// harness builds one screen per theme; sharing one would let the light run
  /// decide where the dark run starts.
  Widget shellWith(FakeDeckRepository repository, {String? location}) {
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

  Widget levelWith(FakeDeckRepository repository) =>
      shellWith(repository, location: '/decks/deck-1');

  /// Lets the pushed route finish laying out before the walk starts.
  ///
  /// A level inside a deck is a *child* route, so mounting it puts two routes in
  /// the branch Navigator and starts a page transition. The audit walks the
  /// render tree, and a route still mid-insertion has boxes that have not been
  /// laid out — walking one throws rather than reporting a colour. Settling first
  /// is not hiding anything: the audit is about the screen at rest.
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle();

  /// A repository serving one deck and the children it should show.
  FakeDeckRepository serving(
    DeckEntity deck, {
    List<DeckSummary> children = const <DeckSummary>[],
  }) => FakeDeckRepository(
    deckList: (_) => Stream<DeckListSnapshot>.value(
      DeckListSnapshot(parent: deck, decks: children, nextDueAt: null),
    ),
    allDecks: () => Stream<List<DeckEntity>>.value(<DeckEntity>[deck]),
  );

  final anchorsWithEmpty = <AuditAnchor>[
    AuditAnchor.type('deck_screen', DeckListScreen),
    AuditAnchor.type('empty_state', MxEmptyState),
    AuditAnchor.type('navigation_bar', MxNavigationBar),
  ];
  final plainAnchors = <AuditAnchor>[
    AuditAnchor.type('deck_screen', DeckListScreen),
    AuditAnchor.type('navigation_bar', MxNavigationBar),
  ];

  // ---- the root level ------------------------------------------------------

  memoxProductionScreenAuditTest(
    'deck_list_screen',
    () => shellWith(FakeDeckRepository()),
    state: 'root_empty',
    anchors: anchorsWithEmpty,
    allowances: <AuditSkipAllowance>[
      ...deckShellAllowances(
        // No app-bar icon button: create moved to the floating action at M4.12,
        // and the root level has no deck of its own to act on. The empty state's
        // own button belongs to the `empty_state` item below, and there is no
        // toolbar — with no decks there is nothing to filter or sort.
        screenIconButtons: 0,
        screenItemId: 'deck_screen',
        hasFloatingAction: true,
      ),
      ...mxActionButtonAllowances('empty_state'),
    ],
  );

  memoxProductionScreenAuditTest(
    'deck_list_screen',
    () => shellWith(
      FakeDeckRepository.withSummaries(<DeckSummary>[
        fakeSummary(
          id: 'deck-1',
          name: 'Japanese N5',
          totalCardCount: 120,
          dueCardCount: 7,
        ),
        fakeSummary(id: 'deck-2', name: 'Spanish verbs', totalCardCount: 40),
        fakeSummary(
          id: 'deck-3',
          name: 'Kanji radicals',
          schedulerType: SchedulerType.sm2,
        ),
      ]),
    ),
    state: 'root_loaded',
    anchors: plainAnchors,
    allowances: <AuditSkipAllowance>[
      ...deckShellAllowances(
        // One action per row, three decks. The app bar's add action became the
        // floating one at M4.12.
        screenIconButtons: 3,
        screenItemId: 'deck_screen',
        // Every row is a tappable card now rather than a ListTile.
        tappableCards: 3,
        // Filter and sort.
        pills: 2,
        hasFloatingAction: true,
      ),
    ],
  );

  memoxProductionScreenAuditTest(
    'deck_list_screen',
    () => shellWith(
      FakeDeckRepository.failing(const DatabaseFailure(message: 'read failed')),
    ),
    state: 'root_error',
    anchors: <AuditAnchor>[
      AuditAnchor.type('deck_screen', DeckListScreen),
      AuditAnchor.type('error_state', MxErrorState),
      AuditAnchor.type('navigation_bar', MxNavigationBar),
    ],
    allowances: <AuditSkipAllowance>[
      ...deckShellAllowances(
        // A failed read renders no rows and no toolbar — there is nothing to
        // filter or order when nothing arrived. The app bar stays: the root
        // level's title is a constant, so it survives a failed read.
        screenIconButtons: 0,
        screenItemId: 'deck_screen',
      ),
      // The Retry button, the only control this state adds.
      ...mxActionButtonAllowances('error_state'),
    ],
  );

  // ---- inside a deck -------------------------------------------------------

  // A sub-deck that has not been fixed to a kind yet. Both create choices are
  // visible — the card one disabled with its reason (BR-61) — so this state
  // carries the notice row as well as the empty state's button.
  memoxProductionScreenAuditTest(
    'deck_list_screen',
    () => levelWith(
      serving(fakeSubDeck(id: 'deck-1', name: 'Unset deck', parentId: 'root')),
    ),
    state: 'level_unset',
    drive: settle,
    anchors: anchorsWithEmpty,
    allowances: <AuditSkipAllowance>[
      // One declared icon button — the action menu — plus the back button the
      // AppBar adds on a pushed route. Create-sub-deck is the floating action.
      ...deckShellAllowances(
        screenIconButtons: 1,
        screenItemId: 'deck_screen',
        hasBackButton: true,
        hasFloatingAction: true,
      ),
      ...mxActionButtonAllowances('empty_state'),
    ],
  );

  // Fixed to decks, and empty. Same chrome as `level_unset` minus the card
  // notice.
  memoxProductionScreenAuditTest(
    'deck_list_screen',
    () => levelWith(
      serving(
        fakeSubDeck(
          id: 'deck-1',
          name: 'Empty deck folder',
          parentId: 'root',
          contentType: DeckContentType.deck,
        ),
      ),
    ),
    state: 'level_empty_deck',
    drive: settle,
    anchors: anchorsWithEmpty,
    allowances: <AuditSkipAllowance>[
      ...deckShellAllowances(
        screenIconButtons: 1,
        screenItemId: 'deck_screen',
        hasBackButton: true,
        hasFloatingAction: true,
      ),
      ...mxActionButtonAllowances('empty_state'),
    ],
  );

  // Children listed — and since the unification they are the same rows the root
  // level draws, counts and all. If this state's allowances ever stop matching
  // `root_loaded`'s shape, the two levels have drifted apart again.
  memoxProductionScreenAuditTest(
    'deck_list_screen',
    () => levelWith(
      serving(
        fakeRootDeck(id: 'deck-1', name: 'Japanese N5'),
        children: <DeckSummary>[
          fakeChildSummary(
            id: 'c1',
            name: 'Hiragana',
            parentId: 'deck-1',
            totalCardCount: 46,
            dueCardCount: 5,
          ),
          fakeChildSummary(
            id: 'c2',
            name: 'Katakana',
            parentId: 'deck-1',
            totalCardCount: 46,
          ),
          fakeChildSummary(
            id: 'c3',
            name: 'Core vocabulary',
            parentId: 'deck-1',
            totalCardCount: 800,
            dueCardCount: 31,
          ),
        ],
      ),
    ),
    state: 'level_loaded',
    drive: settle,
    anchors: plainAnchors,
    allowances: <AuditSkipAllowance>[
      // The action menu and one per child row — plus the AppBar's back button.
      // Three children, so four declared; create-sub-deck is the floating action.
      ...deckShellAllowances(
        screenIconButtons: 4,
        screenItemId: 'deck_screen',
        hasBackButton: true,
        tappableCards: 3,
        pills: 2,
        hasFloatingAction: true,
      ),
    ],
  );

  // Fixed to cards. No deck list and no create-deck action at all (BR-63); the
  // card list itself belongs to M4.11, so this states the handoff instead of
  // offering a control that does nothing. One icon button — the action menu.
  memoxProductionScreenAuditTest(
    'deck_list_screen',
    () => levelWith(
      serving(
        fakeSubDeck(
          id: 'deck-1',
          name: 'Verbs',
          parentId: 'root',
          contentType: DeckContentType.card,
        ),
      ),
    ),
    state: 'level_card_handoff',
    drive: settle,
    anchors: anchorsWithEmpty,
    allowances: <AuditSkipAllowance>[
      ...deckShellAllowances(
        screenIconButtons: 1,
        screenItemId: 'deck_screen',
        hasBackButton: true,
      ),
    ],
  );

  // A deck deleted elsewhere (UC-03 E1). No app-bar actions at all, because
  // there is no deck to act on — so zero icon buttons.
  memoxProductionScreenAuditTest(
    'deck_list_screen',
    () => levelWith(FakeDeckRepository.missingDeck()),
    state: 'level_not_found',
    drive: settle,
    anchors: <AuditAnchor>[
      AuditAnchor.type('deck_screen', DeckListScreen),
      AuditAnchor.type('error_state', MxErrorState),
      AuditAnchor.type('navigation_bar', MxNavigationBar),
    ],
    allowances: <AuditSkipAllowance>[
      // No app-bar title on this state, so one Material layer rather than two,
      // and no icon buttons at all — there is no deck left to act on.
      ...deckShellAllowances(
        screenIconButtons: 0,
        screenItemId: 'deck_screen',
        hasAppBar: false,
      ),
      ...mxActionButtonAllowances('error_state'),
    ],
  );
}
