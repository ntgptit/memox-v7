@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/presentation/screens/progress_deck_screen.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../../../../../features/progress/presentation/support/fake_progress_repository.dart';
import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../audit_rules.dart';
import '../../../../deck_audit_allowances.dart';
import '../../../../memox_audit.dart';
import '../../../../progress_audit_harness.dart';
import '../../../../screen_auditor.dart';

/// Strict visual audit for `ProgressDeckScreen`.
///
/// Companion of
/// `lib/features/progress/presentation/screens/progress_deck_screen.dart`, at
/// the mirrored path. `MX-VIS-001` checks that this file exists, imports that
/// screen and calls the strict helper — a file that merely sits at the right
/// path proves nothing.
///
/// **Audited through the real router**, because this screen is never seen alone:
/// it is always inside the navigation shell with the bottom bar under it.
/// `Router.withConfig` mounts the production route table inside the harness's
/// own `MaterialApp`, so the shell, the branch and the bar are the real ones
/// while the theme under test stays the harness's.
///
/// Three states, and they are the three whose *colours* differ: a level with
/// figures paints the metric tints; a level with decks and no activity paints
/// the neutral fallback across every cell — which is exactly where a zero could
/// accidentally be dressed as an error; and a level with no decks at all paints
/// only the empty state. The middle one is not the same as the last: an earlier
/// version audited "empty" and meant *no decks*, so it rendered an empty state
/// with no metric cell in it and the zero-colour claim above was never checked
/// by anything. Loading is deliberately absent: `CircularProgressIndicator` is
/// mid-animation at any pump, so its paint is not a stable subject, and the
/// widget tests cover it.
///
/// `deckShellAllowances` is reused rather than copied. Despite the name it
/// describes **the app's chrome** — mount any branch inside `AppNavigationShell`
/// and the same unreadable nodes appear — and a second copy of that promise is
/// the one that would stop being true.
/// The two things a state with a list has to name.
///
/// **Here rather than in the harness**, because MX-VIS-001 requires this file to
/// import the screen it audits — and an import the file never uses is an
/// analyzer warning. The anchor list is the one place the screen type is
/// genuinely named, so it is what makes the required import a real one.
final List<AuditAnchor> _plainAnchors = <AuditAnchor>[
  AuditAnchor.type('progress_screen', ProgressDeckScreen),
  AuditAnchor.type('navigation_bar', MxNavigationBar),
];

/// The same, plus the empty state a level with nothing to list renders.
final List<AuditAnchor> _anchorsWithEmpty = <AuditAnchor>[
  AuditAnchor.type('progress_screen', ProgressDeckScreen),
  AuditAnchor.type('empty_state', MxEmptyState),
  AuditAnchor.type('navigation_bar', MxNavigationBar),
];

void main() {
  memoxProductionScreenAuditTest(
    'progress_deck_screen',
    () => progressShellWith(
      FakeProgressRepository.withSnapshot(
        activitySnapshot(
          decks: <DeckActivity>[
            deckActivity(
              deckId: 'busy',
              name: 'Spanish',
              last7Days: activityMetrics(
                activeCards: 42,
                activeDays: 6,
                learning: 12,
                reviewing: 60,
              ),
            ),
            deckActivity(deckId: 'idle', name: 'Idle deck'),
          ],
          scopeLast7Days: activityMetrics(
            activeCards: 45,
            activeDays: 6,
            learning: 12,
            reviewing: 60,
          ),
        ),
      ),
    ),
    state: 'library_mixed',
    // Settled, because the level opens a stream and the first frame is a
    // spinner.
    drive: (tester) => tester.pumpAndSettle(),
    // This screen declares one surface column: every row of cards spans it, or
    // stacks. Opted in explicitly, because a layout rule is a screen's own
    // declaration — not something the harness infers from seeing `MxCard`.
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
    anchors: _plainAnchors,
    allowances: <AuditSkipAllowance>[
      ...deckShellAllowances(
        // No app-bar action: this screen reads and offers nothing to press up
        // there.
        screenIconButtons: 0,
        screenItemId: 'progress_screen',
        // **`tappableCards` is left at its default of zero, and that is a
        // measurement rather than a claim that the rows are not tappable.**
        // This counts hosts the audit *reads*, and since M99.24 `/progress`
        // renders the overview's three sections above this level: at the
        // audit's viewport the deck rows start below the fold — the report says
        // `66 off-surface` — so the only ink hosts on surface are the two range
        // pills. Measured on the composed screen: 4 `_RenderInkFeatures` and 2
        // `CustomPaint (no painter)`, both of which fall out of exactly this one
        // fact.
        pills: 2,
        // No search on this branch.
        hasSearchField: false,
      ),
      const AuditSkipAllowance(
        itemId: 'progress_screen',
        reason: SkipReason.unknownRenderType,
        detailContains: '_RenderPinnedHeaderSliver',
        rationale:
            'PinnedHeaderSliver lays its child out and paints nothing of its own — it has no colour, no border and no shape. The strip it pins is an MxSubheaderBand over a DecoratedBox whose surface colour the audit reads directly, one node below this one.',
      ),
      const AuditSkipAllowance(
        itemId: 'progress_screen',
        reason: SkipReason.rasterNotFlat,
        detailContains: 'covers only 0%',
        rationale:
            'The unselected range pill declares a surface tint that its resting '
            'state does not fill, and `_RenderChip` paints what it does fill '
            'through a private render object. Same case the card list records '
            'for its filter chips; the pill colours are pinned by the '
            'mx_pill_button goldens and the selected/unselected fills are '
            'asserted to differ, in both themes, in mx_pill_button_test.dart.',
      ),
    ],
  );

  memoxProductionScreenAuditTest(
    'progress_deck_screen',
    () => progressShellWith(
      FakeProgressRepository.withSnapshot(
        activitySnapshot(
          decks: <DeckActivity>[
            deckActivity(deckId: 'a', name: 'Spanish'),
            deckActivity(deckId: 'b', name: 'Idle deck'),
          ],
        ),
      ),
    ),
    state: 'library_all_zero',
    // Settled, because the level opens a stream and the first frame is a
    // spinner.
    drive: (tester) => tester.pumpAndSettle(),
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
    anchors: _plainAnchors,
    allowances: <AuditSkipAllowance>[
      ...deckShellAllowances(
        screenIconButtons: 0,
        screenItemId: 'progress_screen',
        // Same reason as above, and `tappableCards` is again left at its
        // default of zero: the rows sit below the fold on the composed screen,
        // so no tappable card is on the surface being read.
        pills: 2,
        hasSearchField: false,
      ),
      const AuditSkipAllowance(
        itemId: 'progress_screen',
        reason: SkipReason.unknownRenderType,
        detailContains: '_RenderPinnedHeaderSliver',
        rationale:
            'PinnedHeaderSliver lays its child out and paints nothing of its own — it has no colour, no border and no shape. The strip it pins is an MxSubheaderBand over a DecoratedBox whose surface colour the audit reads directly, one node below this one.',
      ),
      const AuditSkipAllowance(
        itemId: 'progress_screen',
        reason: SkipReason.rasterNotFlat,
        detailContains: 'covers only 0%',
        rationale:
            'The unselected range pill, exactly as in the mixed state above.',
      ),
    ],
  );

  memoxProductionScreenAuditTest(
    'progress_deck_screen',
    () => progressShellWith(
      // Seeded, because `/progress` renders the overview above this level since
      // M99.24: an unseeded overview leaves a spinner on screen and the audit
      // reports a `CustomPaint` it cannot read rather than the empty level this
      // scenario is about.
      FakeProgressRepository.withSnapshot(emptyActivitySnapshot()),
    ),
    state: 'library_empty',
    // Settled, because the level opens a stream and the first frame is a
    // spinner.
    drive: (tester) => tester.pumpAndSettle(),
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
    anchors: _anchorsWithEmpty,
    allowances: <AuditSkipAllowance>[
      ...deckShellAllowances(
        screenIconButtons: 0,
        screenItemId: 'progress_screen',
        hasSearchField: false,
      ),
      const AuditSkipAllowance(
        itemId: 'progress_screen',
        reason: SkipReason.unknownRenderType,
        detailContains: 'RenderSliverFillRemaining',
        rationale:
            'ProgressHeaderedBody hands this face a '
            'SliverFillRemaining(hasScrollBody: false), so the state is sized '
            'to its content and centred in what the overview band leaves '
            '(SC-C3-18) — the same composition the loaded level and the deck '
            'list already use. Same case as _RenderPinnedHeaderSliver in the '
            'states above: it lays its child out and paints nothing of its own. '
            'Verified against the pinned SDK rather than assumed — '
            'rendering/sliver_fill.dart declares no paint method at all, so '
            'RenderSliverFillRemaining inherits '
            'RenderSliverSingleBoxAdapter.paint, whose whole body is one '
            'context.paintChild. It has no colour, border or shape; the face '
            'under it is anchored as empty_state and read in full.',
      ),
    ],
  );
}
