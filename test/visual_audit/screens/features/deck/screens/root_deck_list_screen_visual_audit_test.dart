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
import 'package:memox/features/deck/domain/models/root_deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/presentation/screens/root_deck_list_screen.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../../../../../features/deck/presentation/support/fake_deck_repository.dart';
import '../../../../audit_allowance.dart';
import '../../../../deck_audit_allowances.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';

/// Strict visual audit for `RootDeckListScreen`.
///
/// Companion of `lib/features/deck/presentation/root_deck_list_screen.dart`, at
/// the mirrored path. `MX-VIS-001` checks that this file exists, imports that
/// screen, and calls the strict helper — a file that merely sits at the right
/// path proves nothing.
///
/// **Audited through the real router, not as a bare screen.** Since M4.10a the
/// deck list is never seen on its own: it is always inside the navigation shell,
/// with the bottom bar under it. Auditing the screen alone would produce an image
/// no user ever sees and would leave the bar's colours unmeasured on every screen
/// it appears on. `Router.withConfig` mounts the production route table inside
/// the harness's own `MaterialApp`, so the shell, the branch and the bar are the
/// real ones while the theme under test stays the harness's.
///
/// Three states. Loading is deliberately absent: `CircularProgressIndicator` is
/// mid-animation at any pump, so its paint is not a stable subject — it is
/// covered by the widget test instead.
///
/// The allowance counts differ per state because the number of icon buttons on
/// screen differs, and every count is exact: `expectedMatches` fails when the
/// number moves at all, in either direction.
void main() {
  /// The production route table, with the database faked out.
  ///
  /// The router is per-call because `GoRouter` carries navigation history and the
  /// harness builds one screen per theme; sharing one would let the light run
  /// decide where the dark run starts.
  Widget shellWith(FakeDeckRepository repository) {
    // No `initialLocation`: the default is already the deck branch, and stating
    // it trips `avoid_redundant_argument_values`, a lint this project promotes to
    // error. That the default *is* Decks is asserted in the router tests.
    final router = createAppRouter();
    addTearDown(router.dispose);

    return ProviderScope(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        deckRepositoryProvider.overrideWithValue(repository),
        // A fixed clock, so the due counts in the loaded state are identical on
        // every run.
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 7, 29, 12)),
      ],
      child: Router.withConfig(config: router),
    );
  }

  memoxProductionScreenAuditTest(
    'root_deck_list_screen',
    () => shellWith(FakeDeckRepository()),
    state: 'empty',
    anchors: <AuditAnchor>[
      AuditAnchor.type('deck_screen', RootDeckListScreen),
      AuditAnchor.type('empty_state', MxEmptyState),
      AuditAnchor.type('navigation_bar', MxNavigationBar),
    ],
    allowances: <AuditSkipAllowance>[
      ...deckShellAllowances(
        // One icon button: the app bar's add action. The empty state's own
        // button belongs to the `empty_state` item below.
        screenIconButtons: 1,
        screenItemId: 'deck_screen',
      ),
      ...mxActionButtonAllowances('empty_state'),
    ],
  );

  memoxProductionScreenAuditTest(
    'root_deck_list_screen',
    () => shellWith(
      FakeDeckRepository.withSummaries(<RootDeckSummary>[
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
    state: 'loaded',
    anchors: <AuditAnchor>[
      AuditAnchor.type('deck_screen', RootDeckListScreen),
      AuditAnchor.type('navigation_bar', MxNavigationBar),
    ],
    allowances: <AuditSkipAllowance>[
      ...deckShellAllowances(
        // The app bar's add action plus one per row. Three decks, so four.
        screenIconButtons: 4,
        screenItemId: 'deck_screen',
      ),
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
    allowances: <AuditSkipAllowance>[
      ...deckShellAllowances(screenIconButtons: 1, screenItemId: 'deck_screen'),
      // The Retry button, the only control this state adds.
      ...mxActionButtonAllowances('error_state'),
    ],
  );
}
