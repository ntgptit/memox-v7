@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../../../../features/deck/presentation/support/fake_deck_repository.dart';
import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../deck_audit_allowances.dart';
import '../../../../deck_audit_harness.dart';
import '../../../../audit_rules.dart';
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
///
/// The fixture — router, fake repository, anchors — is in
/// `deck_audit_harness.dart`, so what is left here is the list of states.
void main() {
  // ---- the root level ------------------------------------------------------

  memoxProductionScreenAuditTest(
    'deck_list_screen',
    () => deckShellWith(FakeDeckRepository()),
    state: 'root_empty',
    // This screen declares one surface column (M99.19a): every row of
    // cards spans it, or stacks. Opted in explicitly, because a layout
    // rule is a screen's own declaration — not something the harness
    // infers from seeing `MxCard`.
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
    anchors: deckAnchorsWithEmpty,
    allowances: <AuditSkipAllowance>[
      ...deckShellAllowances(
        // One declared: the bar's overflow, where the tag catalog and Trash
        // live (T2a). Search is the shell's own count and create floats
        // (owner review, 2026-08-20). Both stay with no decks: an empty
        // catalog is an answer, and the recovery surface matters most before
        // anything is deleted (AD-22). The empty state's button belongs to
        // `empty_state`, and with no decks there is no toolbar to sort.
        screenIconButtons: 1,
        screenItemId: 'deck_screen',
        hasFloatingAction: true,
      ),
      // Two ways forward since UC-01: the starter catalog and the blank deck.
      ...mxActionButtonAllowances('empty_state', buttons: 2),
    ],
  );

  memoxProductionScreenAuditTest(
    'deck_list_screen',
    () => deckShellWith(
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
    // This screen declares one surface column (M99.19a): every row of
    // cards spans it, or stacks. Opted in explicitly, because a layout
    // rule is a screen's own declaration — not something the harness
    // infers from seeing `MxCard`.
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
    anchors: deckPlainAnchors,
    allowances: <AuditSkipAllowance>[
      heroCardRasterAllowance,
      ...deckShellAllowances(
        // One action per row for three decks, plus the summary panel's
        // collapse chevron, plus the bar's one overflow menu (tag catalog and
        // Trash live inside it; search is the shell's own count). Create is
        // the floating action now (owner review, 2026-08-20).
        screenIconButtons: 5,
        hasFloatingAction: true,
        screenItemId: 'deck_screen',
        // Every row is a tappable card now rather than a ListTile.
        tappableCards: 3,
        // Sort alone — the filter moved into the bar's overflow menu.
        pills: 1,
        // One deck in this fixture has cards due, so one Study action — and
        // the summary panel's own Study CTA above the list.
        filledButtons: 2,
      ),
      // One progress bar per deck that has cards; two of the three fixtures do.
      //
      // `LinearProgressIndicator` paints its track and its fill through
      // `_LinearProgressIndicatorPainter`, so neither colour exists on a render
      // object the auditor can read. Both are pinned elsewhere:
      // `mx_progress_bar_test.dart` asserts the fill is `secondary` below 100%
      // and `success` at it, and the track is `surfaceMuted` — read off the
      // widget rather than the raster — and the `mx_progress_bar_*` goldens hold
      // the rendering.
      const AuditSkipAllowance(
        itemId: 'deck_screen',
        reason: SkipReason.customPainter,
        detailContains: '_LinearProgressIndicatorPainter',
        rationale:
            'LinearProgressIndicator paints its track and fill in a '
            'CustomPainter, so no render object carries either colour. Both are '
            'asserted in mx_progress_bar_test.dart and pinned by the '
            'mx_progress_bar_* goldens.',
        // Two of the three fixtures have cards, plus the level summary's own
        // bar above them.
        expectedMatches: 3,
      ),
    ],
  );

  memoxProductionScreenAuditTest(
    'deck_list_screen',
    () => deckShellWith(
      FakeDeckRepository.failing(const DatabaseFailure(message: 'read failed')),
    ),
    state: 'root_error',
    // This screen declares one surface column (M99.19a): every row of
    // cards spans it, or stacks. Opted in explicitly, because a layout
    // rule is a screen's own declaration — not something the harness
    // infers from seeing `MxCard`.
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
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
        hasSearchField: false, // error widget, not the level shell
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
    () => deckLevelWith(
      servingDeckLevel(
        fakeSubDeck(id: 'deck-1', name: 'Unset deck', parentId: 'root'),
      ),
    ),
    state: 'level_unset',
    drive: settleDeckScreen,
    // This screen declares one surface column (M99.19a): every row of
    // cards spans it, or stacks. Opted in explicitly, because a layout
    // rule is a screen's own declaration — not something the harness
    // infers from seeing `MxCard`.
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
    anchors: deckAnchorsWithEmpty,
    allowances: <AuditSkipAllowance>[
      // One declared icon button — the deck's action menu — plus the floating
      // create. One breadcrumb step: no ancestors, so the path is the deck
      // list alone and the way back is the chevron beside it.
      ...deckShellAllowances(
        screenIconButtons: 1,
        screenItemId: 'deck_screen',
        hasFloatingAction: true,
        breadcrumbSteps: 1,
      ),
      ...mxActionButtonAllowances('empty_state'),
    ],
  );

  // Fixed to decks, and empty. Same chrome as `level_unset` minus the card
  // notice.
  memoxProductionScreenAuditTest(
    'deck_list_screen',
    () => deckLevelWith(
      servingDeckLevel(
        fakeSubDeck(
          id: 'deck-1',
          name: 'Empty deck folder',
          parentId: 'root',
          contentType: DeckContentType.deck,
        ),
      ),
    ),
    state: 'level_empty_deck',
    drive: settleDeckScreen,
    // This screen declares one surface column (M99.19a): every row of
    // cards spans it, or stacks. Opted in explicitly, because a layout
    // rule is a screen's own declaration — not something the harness
    // infers from seeing `MxCard`.
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
    anchors: deckAnchorsWithEmpty,
    allowances: <AuditSkipAllowance>[
      ...deckShellAllowances(
        screenIconButtons: 1,
        screenItemId: 'deck_screen',
        hasFloatingAction: true,
        breadcrumbSteps: 1,
      ),
      ...mxActionButtonAllowances('empty_state'),
    ],
  );

  // Children listed — and since the unification they are the same rows the root
  // level draws, counts and all. If this state's allowances ever stop matching
  // `root_loaded`'s shape, the two levels have drifted apart again.
  memoxProductionScreenAuditTest(
    'deck_list_screen',
    () => deckLevelWith(
      servingDeckLevel(
        fakeSubDeck(id: 'deck-1', name: 'Kana', parentId: 'branch'),
        ancestors: fakePath(<String>['Japanese N5', 'Writing systems']),
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
    drive: settleDeckScreen,
    // This screen declares one surface column (M99.19a): every row of
    // cards spans it, or stacks. Opted in explicitly, because a layout
    // rule is a screen's own declaration — not something the harness
    // infers from seeing `MxCard`.
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
    anchors: deckPlainAnchors,
    allowances: <AuditSkipAllowance>[
      // The action menu and one per child row — plus the AppBar's back button.
      // Three children, so four declared, plus create and the deck action menu.
      // Three breadcrumb steps: the deck list, then the two ancestors. The
      // strip's last step — the deck the user is in — is text rather than a
      // control, so it hosts no ink.
      heroCardRasterAllowance,
      ...deckShellAllowances(
        // Three row menus, the deck's overflow and the panel's collapse
        // chevron. Create floats, and the way back is the path's own chevron
        // rather than the bar's platform arrow (owner review, 2026-08-20).
        screenIconButtons: 5,
        screenItemId: 'deck_screen',
        hasFloatingAction: true,
        tappableCards: 3,
        // Sort alone — the filter lives in the deck's own overflow now.
        pills: 1,
        // Two of the three children have cards due, and the summary panel's
        // Study CTA makes a third filled action.
        filledButtons: 3,
        breadcrumbSteps: 3,
      ),
      // Three cards, all with cards, plus the level summary's own bar.
      // The count is exact on purpose — an allowance that said "any number" would
      // stop noticing when a bar appears on a row that should not have one.
      const AuditSkipAllowance(
        itemId: 'deck_screen',
        reason: SkipReason.customPainter,
        detailContains: '_LinearProgressIndicatorPainter',
        rationale:
            'LinearProgressIndicator paints its track and fill in a '
            'CustomPainter, so no render object carries either colour. Both are '
            'asserted in mx_progress_bar_test.dart and pinned by the '
            'mx_progress_bar_* goldens.',
        expectedMatches: 4,
      ),
    ],
  );

  // Fixed to cards. No deck list and no create-deck action at all (BR-63); the
  // card list itself belongs to M4.11, so this states the handoff instead of
  // offering a control that does nothing. One icon button — the action menu.
  memoxProductionScreenAuditTest(
    'deck_list_screen',
    () => deckLevelWith(
      servingDeckLevel(
        fakeSubDeck(
          id: 'deck-1',
          name: 'Verbs',
          parentId: 'root',
          contentType: DeckContentType.card,
        ),
      ),
    ),
    state: 'level_card_handoff',
    drive: settleDeckScreen,
    // This screen declares one surface column (M99.19a): every row of
    // cards spans it, or stacks. Opted in explicitly, because a layout
    // rule is a screen's own declaration — not something the harness
    // infers from seeing `MxCard`.
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
    anchors: deckAnchorsWithEmpty,
    allowances: <AuditSkipAllowance>[
      ...deckShellAllowances(
        screenIconButtons: 1,
        screenItemId: 'deck_screen',
        // The deck list step, and the chevron beside it — the way back lives
        // on the path line now (owner review, 2026-08-20).
        breadcrumbSteps: 1,
      ),
      // The "Open cards" action that hands off to the card list (M4.11).
      ...mxActionButtonAllowances('empty_state'),
    ],
  );

  // A deck deleted elsewhere (UC-03 E1). No app-bar actions at all, because
  // there is no deck to act on — so zero icon buttons.
  memoxProductionScreenAuditTest(
    'deck_list_screen',
    () => deckLevelWith(FakeDeckRepository.missingDeck()),
    state: 'level_not_found',
    drive: settleDeckScreen,
    // This screen declares one surface column (M99.19a): every row of
    // cards spans it, or stacks. Opted in explicitly, because a layout
    // rule is a screen's own declaration — not something the harness
    // infers from seeing `MxCard`.
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
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
        hasSearchField: false, // error widget, not the level shell
      ),
      ...mxActionButtonAllowances('error_state'),
    ],
  );
}
