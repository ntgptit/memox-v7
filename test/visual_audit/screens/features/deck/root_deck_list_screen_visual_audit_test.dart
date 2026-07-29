@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/di/deck_repository_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/deck_entity.dart';
import 'package:memox/features/deck/presentation/root_deck_list_screen.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../../../../features/deck/presentation/support/fake_deck_repository.dart';
import '../../../audit_allowance.dart';
import '../../../audit_model.dart';
import '../../../memox_audit.dart';
import '../../../screen_auditor.dart';

/// Strict visual audit for `RootDeckListScreen`.
///
/// Companion of `lib/features/deck/presentation/root_deck_list_screen.dart`, at
/// the mirrored path. `MX-VIS-001` checks that this file exists, imports that
/// screen, and calls the strict helper — a file that merely sits at the right
/// path proves nothing.
///
/// **Audited through the real router, not as a bare screen.** Since M4.10a the
/// deck list is never seen on its own: it is always inside the navigation
/// shell, with the bottom bar under it. Auditing the screen alone would produce
/// an image no user ever sees and would leave the bar's colours unmeasured on
/// every screen it appears on. `Router.withConfig` mounts the production route
/// table inside the harness's own `MaterialApp`, so the shell, the branch and
/// the bar are the real ones while the theme under test stays the harness's.
///
/// Three states, not one. A screen audited only at rest is a screen where the
/// states a user actually spends time in are unchecked, and empty/error are the
/// two most likely to have been styled by hand. Loading is deliberately absent:
/// `CircularProgressIndicator` is mid-animation at any pump, so its paint is
/// not a stable subject — it is covered by the widget test instead.
///
/// The bar is held to `complete` here as a side effect of appearing on this
/// screen. Its own component-level pixels are pinned by the
/// `mx_navigation_bar_*` goldens.
void main() {
  /// The production route table, with the database faked out.
  ///
  /// The router is per-call because `GoRouter` carries navigation history and
  /// the harness builds one screen per theme; sharing one would let the light
  /// run decide where the dark run starts.
  Widget shellWith(FakeDeckRepository repository) {
    // No `initialLocation`: the default is already the deck branch, and stating
    // it trips `avoid_redundant_argument_values`, a lint this project promotes
    // to error. That the default *is* Decks is asserted in the router tests.
    final router = createAppRouter();
    addTearDown(router.dispose);

    return ProviderScope(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        deckRepositoryProvider.overrideWithValue(repository),
      ],
      child: Router.withConfig(config: router),
    );
  }

  /// The page-transition backdrops — one per `Navigator` in the tree.
  ///
  /// **Not the Scaffold backgrounds**, despite what the older audits in this
  /// repository claimed. Every opaque route is wrapped by
  /// `_FadeForwardsPageTransition`, which paints
  /// `ColoredBox(color: secondaryAnimation.isAnimating ? surface :
  /// Colors.transparent)` — verified in `page_transitions_theme.dart` of the
  /// pinned SDK (3.44.8). At rest, which is when this audit samples, the value
  /// is transparent and the node contributes no colour at all; the only
  /// non-transparent value it can take is `ColorScheme.surface`, a palette
  /// token.
  ///
  /// Three of them because there are three Navigators: the harness's own
  /// `MaterialApp`, GoRouter's root, and the branch. That is also why a
  /// single-screen audit of the same shape reports exactly one.
  const pageTransitionBackdrops = AuditSkipAllowance(
    itemId: 'screen',
    reason: SkipReason.rasterOnly,
    detailContains: '_RenderColoredBox',
    expectedMatches: 3,
    rationale:
        'Page-transition backdrops from _FadeForwardsPageTransition, one per '
        'Navigator (harness MaterialApp, GoRouter root, branch). At rest each '
        'paints Colors.transparent; mid-transition it paints ColorScheme'
        '.surface, which is a palette token. Verified against '
        'page_transitions_theme.dart in the pinned SDK.',
  );

  /// Material ink layers outside the branch screen: the shell's Scaffold.
  const shellInk = AuditSkipAllowance(
    itemId: 'screen',
    reason: SkipReason.rasterOnly,
    detailContains: '_RenderInkFeatures',
    rationale:
        "The navigation shell Scaffold's Material layer. A Material paints its "
        'own background and its splash and highlight into this layer, so none '
        'of the three is readable from a render object; scaffoldBackgroundColor '
        'and the overlay colours are asserted in app_theme_test.dart.',
  );

  /// Material ink layers inside the branch screen: its Scaffold and its AppBar.
  const branchInk = AuditSkipAllowance(
    itemId: 'deck_screen',
    reason: SkipReason.rasterOnly,
    detailContains: '_RenderInkFeatures',
    expectedMatches: 2,
    rationale:
        "The branch screen's own Scaffold and AppBar ink layers, from "
        'MxContentShell. Same raster-only reason as the shell above.',
  );

  /// The bottom bar's ink layer, where the selection indicator is painted.
  const navigationBarInk = AuditSkipAllowance(
    itemId: 'navigation_bar',
    reason: SkipReason.rasterOnly,
    detailContains: '_RenderInkFeatures',
    rationale:
        'NavigationBar paints its selection indicator into a Material ink '
        'layer, so the pill has no render object of its own. Its colour is '
        'secondaryContainer, set in navigationBarTheme, and the two selected '
        'states are pinned by the mx_navigation_bar_* goldens.',
  );

  memoxProductionScreenAuditTest(
    'root_deck_list_screen',
    () => shellWith(FakeDeckRepository.emitting(const <DeckEntity>[])),
    state: 'empty',
    anchors: <AuditAnchor>[
      AuditAnchor.type('deck_screen', RootDeckListScreen),
      AuditAnchor.type('empty_state', MxEmptyState),
      AuditAnchor.type('navigation_bar', MxNavigationBar),
    ],
    allowances: const <AuditSkipAllowance>[
      pageTransitionBackdrops,
      shellInk,
      branchInk,
      navigationBarInk,
    ],
  );

  memoxProductionScreenAuditTest(
    'root_deck_list_screen',
    () => shellWith(
      FakeDeckRepository.emitting(<DeckEntity>[
        fakeRootDeck(id: 'deck-1', name: 'Japanese N5'),
        fakeRootDeck(id: 'deck-2', name: 'Spanish verbs'),
        fakeRootDeck(id: 'deck-3', name: 'Kanji radicals'),
      ]),
    ),
    state: 'loaded',
    anchors: <AuditAnchor>[
      AuditAnchor.type('deck_screen', RootDeckListScreen),
      AuditAnchor.type('navigation_bar', MxNavigationBar),
    ],
    allowances: const <AuditSkipAllowance>[
      pageTransitionBackdrops,
      shellInk,
      branchInk,
      navigationBarInk,
    ],
  );

  memoxProductionScreenAuditTest(
    'root_deck_list_screen',
    () => shellWith(
      FakeDeckRepository.failing(const DatabaseFailure(message: 'read failed')),
    ),
    state: 'error',
    anchors: <AuditAnchor>[
      AuditAnchor.type('deck_screen', RootDeckListScreen),
      AuditAnchor.type('error_state', MxErrorState),
      AuditAnchor.type('navigation_bar', MxNavigationBar),
    ],
    allowances: const <AuditSkipAllowance>[
      pageTransitionBackdrops,
      shellInk,
      branchInk,
      navigationBarInk,
      // The Retry button, the only thing this state adds over the empty one.
      AuditSkipAllowance(
        itemId: 'error_state',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        rationale:
            "OutlinedButton draws its border with a CustomPainter, so the "
            "stroke exists in no render object — the audit's own SkipReason "
            'doc names this case. The stroke is the Material 3 `outline` role '
            'and is pinned by the `button_secondary` golden (M4.8); the label '
            'contrast against page and card is asserted in app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'error_state',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        rationale:
            "The Retry button's own Material ink layer. Same reason as the "
            'shell above.',
      ),
    ],
  );
}
