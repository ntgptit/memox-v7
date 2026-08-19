@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/core/time/delay_provider.dart';
import 'package:memox/features/search/di/library_search_repository_provider.dart';
import 'package:memox/features/search/domain/models/search_result_model.dart';
import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import '../../../../../features/search/presentation/support/fake_library_search_repository.dart';
import '../../../../../features/search/presentation/support/search_screen_harness.dart';
import '../../../../audit_allowance.dart';
import '../../../../deck_audit_allowances.dart';
import '../../../../audit_model.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';

/// Strict visual audit for `LibrarySearchScreen`.
///
/// Companion of
/// `lib/features/search/presentation/screens/library_search_screen.dart`, at the
/// mirrored path. `MX-VIS-001` checks that this file exists, imports that
/// screen, and calls the strict helper.
///
/// **Audited as a bare screen rather than through the router.** The search
/// surface renders the same inside the shell as out of it — it has no branch
/// state, no breadcrumb and no bottom-bar interaction — so mounting the route
/// table would add three Navigators' worth of allowances and prove nothing the
/// deck companion does not already prove.
///
/// **Loading is deliberately absent.** `CircularProgressIndicator` is
/// mid-animation at any pump, so its paint is not a stable subject; the widget
/// tests cover it instead.
void main() {
  Widget searchWith(FakeLibrarySearchRepository repository) => ProviderScope(
    overrides: [
      envConfigProvider.overrideWithValue(EnvConfig.development),
      librarySearchRepositoryProvider.overrideWithValue(repository),
      delaySchedulerProvider.overrideWithValue(immediateScheduler),
    ],
    child: const LibrarySearchScreen(),
  );

  Future<void> Function(WidgetTester) typing(String query) =>
      (WidgetTester tester) async {
        await tester.enterText(find.byType(TextField), query);
        await tester.pumpAndSettle();
      };

  memoxProductionScreenAuditTest(
    'library_search_screen',
    () => searchWith(FakeLibrarySearchRepository.serving(fakeSearchPage())),
    anchors: <AuditAnchor>[
      AuditAnchor.type('shell', MxContentShell),
      AuditAnchor.type('empty_state', MxEmptyState),
    ],
    allowances: <AuditSkipAllowance>[...searchShellAllowances()],
  );

  memoxProductionScreenAuditTest(
    'library_search_screen',
    () => searchWith(
      FakeLibrarySearchRepository.serving(
        fakeSearchPage(
          decks: <DeckSearchHit>[
            fakeDeckHit(),
            fakeDeckHit(
              id: 'deck-2',
              name: 'Noun forms',
              isCardDeck: true,
              path: <String>['Korean'],
            ),
          ],
          cards: <CardSearchHit>[
            fakeCardHit(),
            fakeCardHit(id: 'card-2', front: 'tagged', matchedTagName: 'noun'),
          ],
          hasMore: true,
        ),
      ),
    ),
    state: 'results',
    drive: typing('noun'),
    anchors: <AuditAnchor>[AuditAnchor.type('shell', MxContentShell)],
    allowances: <AuditSkipAllowance>[
      // Four rows, the field's clear button, and the load-more text button.
      ...searchShellAllowances(rows: 4, hasClearButton: true, textButtons: 1),
    ],
  );

  memoxProductionScreenAuditTest(
    'library_search_screen',
    () => searchWith(FakeLibrarySearchRepository.failing()),
    state: 'failed',
    drive: typing('noun'),
    anchors: <AuditAnchor>[
      AuditAnchor.type('shell', MxContentShell),
      AuditAnchor.type('error_state', MxErrorState),
    ],
    allowances: <AuditSkipAllowance>[
      ...searchShellAllowances(hasClearButton: true),
      ...mxActionButtonAllowances('error_state'),
    ],
  );
}

/// The raster-only surfaces every state of this screen carries.
///
/// **One list rather than three copies**, for the reason the deck companion
/// gives: the counts differ per state and everything else does not, so a copy
/// per state is three places to fix when the shell changes.
List<AuditSkipAllowance> searchShellAllowances({
  int rows = 0,
  bool hasClearButton = false,
  int textButtons = 0,
}) {
  final int inkHosts = rows + (hasClearButton ? 1 : 0) + textButtons;
  // The clear button and the load-more button each draw their own shape.
  final int shapeBorders = (hasClearButton ? 1 : 0) + textButtons;

  return <AuditSkipAllowance>[
    // ---- the text field --------------------------------------------------
    //
    // **The first audited screen in the repository with an open input**, so
    // these five entries are new rather than copied. The deck level's field was
    // collapsed to a glyph in every state it audits, which is why its harness
    // says the field "exists only after the toggle is pressed" — this screen is
    // that state.
    //
    // None of the five is a colour anyone can read from the render tree, and
    // every one of them is pinned elsewhere: `mx_search_field_test.dart` asserts
    // the fill and the border off the widget, and the `mx_search_field_*`
    // goldens hold the rendering.
    const AuditSkipAllowance(
      itemId: 'screen',
      reason: SkipReason.unknownRenderType,
      detailContains: 'RenderFollowerLayer',
      rationale:
          "The text field's magnifier/toolbar follower. It positions a layer "
          'and paints nothing of its own; the overlays it would carry are not '
          'mounted at rest.',
    ),
    const AuditSkipAllowance(
      itemId: 'shell',
      reason: SkipReason.rasterOnly,
      detailContains: '_RenderDecoration',
      rationale:
          "InputDecorator's own render object. MxSearchField sets every border "
          'to none and draws the pill itself, so this paints nothing; the pill '
          'fill and focus ring are asserted in mx_search_field_test.dart.',
    ),
    const AuditSkipAllowance(
      itemId: 'shell',
      reason: SkipReason.rasterOnly,
      // **`RenderEditable paints`, not `RenderEditable`.** The bare name is a
      // substring of `_RenderEditableCustomPaint`, so it swallowed both of
      // those and the auditor reported a conflict and a miscount rather than
      // the two separate things they are.
      detailContains: 'RenderEditable paints',
      rationale:
          'The editable text itself. Its colour comes from the resolved '
          'TextStyle rather than from a paint on the render object; the body '
          'text roles are asserted in app_theme_test.dart.',
    ),
    const AuditSkipAllowance(
      itemId: 'shell',
      reason: SkipReason.rasterOnly,
      detailContains: '_RenderEditableCustomPaint',
      // The caret painter and the selection painter, one each.
      expectedMatches: 2,
      rationale:
          "RenderEditable's caret and selection painters. Both draw through a "
          'CustomPainter, so neither colour lives on a render object; both come '
          'from the input theme, asserted in app_theme_test.dart.',
    ),
    AuditSkipAllowance(
      itemId: 'shell',
      reason: SkipReason.customPainter,
      detailContains: 'CustomPaint (no painter)',
      // The field's own painter host, plus one per row: an `InkWell` mounts a
      // `CustomPaint` for its splash clip and attaches no painter until a
      // splash exists.
      expectedMatches: 1 + rows,
      rationale:
          'Painter hosts with nothing attached at rest — the text field until a '
          'caret or selection exists, and each row until it is touched. Neither '
          'draws anything in the frame under audit.',
    ),
    const AuditSkipAllowance(
      itemId: 'screen',
      reason: SkipReason.rasterOnly,
      detailContains: '_RenderColoredBox',
      rationale:
          'The page-transition backdrop of this route. '
          '_FadeForwardsPageTransition wraps every opaque route in a ColoredBox '
          'that paints Colors.transparent at rest and ColorScheme.surface only '
          'mid-transition. It is NOT the Scaffold background, which is asserted '
          'in app_theme_test.dart.',
    ),
    AuditSkipAllowance(
      itemId: 'shell',
      reason: SkipReason.rasterOnly,
      detailContains: '_RenderInkFeatures',
      // The Scaffold plus the AppBar, plus one Material per tappable row and
      // per button — each paints its own splash and highlight into its own ink
      // layer, so none of the three colours lives on a render object.
      expectedMatches: 2 + inkHosts,
      rationale:
          'Material ink layers. Splash and highlight are painted onto Material, '
          'so no render object carries them; the overlay colours are asserted in '
          'app_theme_test.dart.',
    ),
    if (shapeBorders > 0)
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        expectedMatches: shapeBorders,
        rationale:
            'IconButton and TextButton draw their shape with a CustomPainter, '
            'so the stroke exists in no render object. Both are transparent at '
            'rest here; their foreground roles are asserted in '
            'app_theme_test.dart and pinned by the button goldens.',
      ),
  ];
}
