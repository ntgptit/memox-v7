@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/study/di/study_home_repository_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';

import '../features/study/domain/support/fake_study_home_repository.dart';
import '../features/study/domain/support/fake_study_repository.dart';
import '../support/study_render.dart';
import '../visual_audit/deck_audit_harness.dart';

/// Device-faithful renders of `StudyEntryScreen` (UC-15) — the deck-level way
/// into a session, and the last screen in the Study feature with no picture of
/// itself.
///
/// **The populated state.** Both counts non-zero, so the readout row carries
/// real numbers and both ways in are present: with nothing new there is no
/// learning entry and with nothing due no review entry at all (BR-29, BR-145),
/// which is strictly less to look at rather than something different. It is the
/// same state `study_entry_screen_visual_audit_test.dart` measures, so the
/// picture and the geometry describe one screen.
///
/// **Mounted through the router, not as a bare widget.** The screen is a pushed
/// route inside a shell branch, so pumping `StudyEntryScreen` on its own loses
/// the bottom navigation bar and the safe area the branch imposes — the flaw
/// `deck_starter_demo_test.dart` records, and the reason `study_home`'s own
/// render could not be scored for density.
///
/// `/study/<id>` rather than `/decks/<id>/study`: both routes build this exact
/// screen (`app_router.dart` names them `studyDeck` and `deckStudy`), and the
/// Study branch is the path a user actually walks — Study Home lists the decks
/// with work waiting and this is where tapping one lands (UC-14). It also keeps
/// the doubles to this feature's two contracts.
void main() {
  /// One scope per render. The router carries navigation history and the home
  /// fake owns a `StreamController`, so sharing either would let the light run
  /// decide what the dark run starts from.
  Widget scope(Brightness brightness) {
    // The branch root under the pushed entry screen. `StudyHomeScreen` is built
    // as the first page of the Study branch's stack even though the entry
    // screen covers it, so its contract has to be satisfied too.
    final home = FakeStudyHomeRepository();
    addTearDown(home.dispose);

    return ProviderScope(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        // Fixed clock and offset: `WatchStudyEntryUseCase` measures "due"
        // against the instant it is handed and `ResumeStudyDayUseCase` needs a
        // study day, so a real clock would render a different screen every run
        // (AD-16).
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 7, 29, 12)),
        utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
        // The one seam behind all three reads this screen makes —
        // `studyEntryProvider` (3 new, 4 due), `studyResumeProvider` (no open
        // session, so no resume sheet is thrown over the render) and
        // `studyReviewOptionsProvider` (an `eight_box` deck).
        studyRepositoryProvider.overrideWithValue(FakeStudyRepository()),
        studyHomeRepositoryProvider.overrideWithValue(home),
      ],
      child: ReviewApp(
        home: deckRouterAt('/study/deck-1'),
        brightness: brightness,
      ),
    );
  }

  testWidgets('study entry — new and due, light', (tester) async {
    await pumpReview(tester, scope(Brightness.light));

    await matchesReviewGolden('goldens/study_entry_light.png');
  });

  testWidgets('study entry — new and due, dark', (tester) async {
    await pumpReview(tester, scope(Brightness.dark));

    await matchesReviewGolden('goldens/study_entry_dark.png');
  });
}
