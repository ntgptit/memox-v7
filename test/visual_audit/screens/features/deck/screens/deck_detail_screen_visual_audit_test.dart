@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_detail_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_detail_screen.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../../../../../features/deck/presentation/support/fake_deck_repository.dart';
import '../../../../audit_allowance.dart';
import '../../../../deck_audit_allowances.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';

/// Strict visual audit for `DeckDetailScreen`.
///
/// Companion of `lib/features/deck/presentation/deck_detail_screen.dart`, at the
/// mirrored path.
///
/// Audited through the real router at `/decks/deck-1`, for the same reason the
/// root list is: this screen is a child route inside the Decks branch, so the
/// bottom bar is part of what the user sees and part of what must be measured.
/// A bare pump would also miss the nested-route chrome entirely.
///
/// **Five states, because this screen has five genuinely different bodies** and
/// the content type decides which. An `unset` deck and a `card` deck are not the
/// same screen with different data — they offer different actions (BR-61 vs
/// BR-63), so auditing one would leave the other's colours unread.
///
/// Loading is deliberately absent: the spinner is mid-animation at any pump.
void main() {
  /// The production route table at a deck, with the repository faked.
  Widget shellWith(FakeDeckRepository repository) {
    final router = createAppRouter(initialLocation: '/decks/deck-1');
    addTearDown(router.dispose);

    return ProviderScope(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        deckRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 7, 29, 12)),
      ],
      child: Router.withConfig(config: router),
    );
  }

  /// Lets the pushed route finish laying out before the walk starts.
  ///
  /// This screen is a *child* route, so mounting it puts two routes in the branch
  /// Navigator and starts a page transition. The audit walks the render tree, and
  /// a route still mid-insertion has boxes that have not been laid out — walking
  /// one throws rather than reporting a colour. Settling first is not hiding
  /// anything: the audit is about the screen at rest, which is what the user
  /// looks at.
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle();

  /// A repository serving one deck and the children it should show.
  FakeDeckRepository serving(
    DeckEntity deck, {
    List<DeckEntity> children = const <DeckEntity>[],
  }) => FakeDeckRepository(
    deckDetail: (_) =>
        Stream<DeckDetail>.value(DeckDetail(deck: deck, childDecks: children)),
    allDecks: () => Stream<List<DeckEntity>>.value(<DeckEntity>[deck]),
  );

  final anchorsWithEmpty = <AuditAnchor>[
    AuditAnchor.type('deck_screen', DeckDetailScreen),
    AuditAnchor.type('empty_state', MxEmptyState),
    AuditAnchor.type('navigation_bar', MxNavigationBar),
  ];

  // A sub-deck that has not been fixed to a kind yet. Both create choices are
  // visible — the card one disabled with its reason (BR-61) — so this state
  // carries the notice row as well as the empty state's button.
  memoxProductionScreenAuditTest(
    'deck_detail_screen',
    () => shellWith(
      serving(fakeSubDeck(id: 'deck-1', name: 'Unset deck', parentId: 'root')),
    ),
    state: 'unset',
    drive: settle,
    anchors: anchorsWithEmpty,
    allowances: <AuditSkipAllowance>[
      // Two declared icon buttons — create-sub-deck and the action menu — plus
      // the back button the AppBar adds on a pushed route.
      ...deckShellAllowances(
        screenIconButtons: 2,
        screenItemId: 'deck_screen',
        hasBackButton: true,
      ),
      ...mxActionButtonAllowances('empty_state'),
    ],
  );

  // Fixed to decks, and empty. Same chrome as `unset` minus the card notice.
  memoxProductionScreenAuditTest(
    'deck_detail_screen',
    () => shellWith(
      serving(
        fakeSubDeck(
          id: 'deck-1',
          name: 'Empty deck folder',
          parentId: 'root',
          contentType: DeckContentType.deck,
        ),
      ),
    ),
    state: 'empty_deck',
    drive: settle,
    anchors: anchorsWithEmpty,
    allowances: <AuditSkipAllowance>[
      ...deckShellAllowances(
        screenIconButtons: 2,
        screenItemId: 'deck_screen',
        hasBackButton: true,
      ),
      ...mxActionButtonAllowances('empty_state'),
    ],
  );

  // Children listed. Each row carries its own action button, so the icon count
  // grows with the fixture — which is exactly what the exact counts catch.
  memoxProductionScreenAuditTest(
    'deck_detail_screen',
    () => shellWith(
      serving(
        fakeRootDeck(id: 'deck-1', name: 'Japanese N5'),
        children: <DeckEntity>[
          fakeSubDeck(id: 'c1', name: 'Hiragana', parentId: 'deck-1'),
          fakeSubDeck(id: 'c2', name: 'Katakana', parentId: 'deck-1'),
          fakeSubDeck(id: 'c3', name: 'Core vocabulary', parentId: 'deck-1'),
        ],
      ),
    ),
    state: 'loaded',
    drive: settle,
    anchors: <AuditAnchor>[
      AuditAnchor.type('deck_screen', DeckDetailScreen),
      AuditAnchor.type('navigation_bar', MxNavigationBar),
    ],
    allowances: <AuditSkipAllowance>[
      // Create-sub-deck, the action menu, and one per child row — plus the
      // AppBar's back button.
      ...deckShellAllowances(
        screenIconButtons: 5,
        screenItemId: 'deck_screen',
        hasBackButton: true,
      ),
    ],
  );

  // Fixed to cards. No deck list and no create-deck action at all (BR-63); the
  // card list itself belongs to M4.11, so this states the handoff instead of
  // offering a control that does nothing. One icon button — the action menu.
  memoxProductionScreenAuditTest(
    'deck_detail_screen',
    () => shellWith(
      serving(
        fakeSubDeck(
          id: 'deck-1',
          name: 'Verbs',
          parentId: 'root',
          contentType: DeckContentType.card,
        ),
      ),
    ),
    state: 'card_handoff',
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
    'deck_detail_screen',
    () => shellWith(
      FakeDeckRepository.failing(
        const NotFoundFailure(message: 'That deck no longer exists.'),
      ),
    ),
    state: 'not_found',
    drive: settle,
    anchors: <AuditAnchor>[
      AuditAnchor.type('deck_screen', DeckDetailScreen),
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
