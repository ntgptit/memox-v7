@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/core/time/delay_provider.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/reminder/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminder/di/reminder_settings_repository_provider.dart';
import 'package:memox/features/reminder/di/reminder_workload_repository_provider.dart';
import 'package:memox/features/reminder/domain/models/reminder_settings_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_time_model.dart';
import 'package:memox/features/search/di/library_search_repository_provider.dart';
import 'package:memox/features/search/domain/models/search_result_model.dart';
import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
import 'package:memox/features/reminder/presentation/screens/reminder_settings_screen.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/core/time/clock_provider.dart';

import '../features/progress/presentation/support/fake_progress_repository.dart';
import '../features/reminder/support/fake_reminder_platform.dart';
import '../features/search/presentation/support/fake_library_search_repository.dart';
import '../features/search/presentation/support/search_screen_harness.dart';
import '../features/settings/domain/support/fake_app_settings_repository.dart';
import '../features/study/domain/support/fake_study_home_repository.dart';
import '../features/trash/presentation/support/fake_trash_repository.dart';
import '../support/study_render.dart';
import '../visual_audit/progress_audit_harness.dart';
import '../visual_audit/settings_audit_harness.dart';
import '../visual_audit/study_audit_harness.dart';
import '../visual_audit/trash_audit_harness.dart';

/// Device-faithful renders of the seven screens the demo suite did not cover:
/// Study Home, Progress at both levels, Settings, the daily reminder, Global
/// Library Search and Trash.
///
/// The gap this closes is the same one `deck_screens_demo_test.dart` names for
/// the deck list: each of these screens was pinned by geometry and color
/// audits, but had no picture of itself for a human to look at. Mounted over
/// the same fakes the visual audits use, so what is captured is the shipped
/// screen, not a drawing of it.
void main() {
  for (final (String mode, Brightness brightness) in <(String, Brightness)>[
    ('light', Brightness.light),
    ('dark', Brightness.dark),
  ]) {
    testWidgets('study home — resume and workload, $mode', (tester) async {
      await pumpReview(
        tester,
        ReviewApp(
          home: studyHomeScreenWith(
            FakeStudyHomeRepository(
              initial: fakeStudyHome(resume: fakeStudyHomeResume()),
            ),
            const StudyHomeScreen(),
          ),
          brightness: brightness,
        ),
      );
      await matchesReviewGolden('goldens/study_home_$mode.png');
    });

    testWidgets('progress overview — streak and totals, $mode', (tester) async {
      await pumpReview(
        tester,
        ReviewApp(home: progressScreenWith(), brightness: brightness),
      );
      await matchesReviewGolden('goldens/progress_overview_$mode.png');
    });

    testWidgets('progress by deck — library level, $mode', (tester) async {
      await pumpReview(
        tester,
        ReviewApp(
          home: progressShellWith(
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
          brightness: brightness,
        ),
      );
      await matchesReviewGolden('goldens/progress_deck_$mode.png');
    });

    testWidgets('settings — study defaults and appearance, $mode', (
      tester,
    ) async {
      await pumpReview(
        tester,
        ReviewApp(
          home: settingsScreenWith(
            FakeAppSettingsRepository(),
            const SettingsScreen(),
          ),
          brightness: brightness,
        ),
      );
      await matchesReviewGolden('goldens/settings_$mode.png');
    });

    testWidgets('reminder settings — enabled, $mode', (tester) async {
      await pumpReview(
        tester,
        ReviewApp(
          home: ProviderScope(
            overrides: [
              reminderSettingsRepositoryProvider.overrideWithValue(
                FakeReminderSettings(
                  const ReminderSettingsModel(
                    isEnabled: true,
                    time: ReminderTime.suggested,
                  ),
                ),
              ),
              reminderPlatformRepositoryProvider.overrideWithValue(
                FakeReminderPlatform(),
              ),
              reminderWorkloadRepositoryProvider.overrideWithValue(
                FakeReminderWorkload(),
              ),
              clockProvider.overrideWithValue(
                () => DateTime.utc(2026, 7, 29, 3),
              ),
              utcOffsetProvider.overrideWithValue(
                () => const Duration(hours: 7),
              ),
            ],
            child: const ReminderSettingsScreen(),
          ),
          brightness: brightness,
        ),
      );
      await matchesReviewGolden('goldens/reminder_settings_$mode.png');
    });

    testWidgets('library search — mixed results, $mode', (tester) async {
      await pumpReview(
        tester,
        ReviewApp(
          home: ProviderScope(
            overrides: [
              envConfigProvider.overrideWithValue(EnvConfig.development),
              librarySearchRepositoryProvider.overrideWithValue(
                FakeLibrarySearchRepository.serving(
                  fakeSearchPage(
                    decks: <DeckSearchHit>[fakeDeckHit(id: 'd9')],
                    cards: <CardSearchHit>[
                      fakeCardHit(),
                      fakeCardHit(
                        id: 'c2',
                        front: 'a common noun',
                        back: 'một danh từ thông dụng',
                        matchedTagName: 'noun',
                      ),
                    ],
                  ),
                ),
              ),
              delaySchedulerProvider.overrideWithValue(immediateScheduler),
            ],
            child: const LibrarySearchScreen(),
          ),
          brightness: brightness,
        ),
      );
      await tester.enterText(find.byType(TextField), 'noun');
      await tester.pumpAndSettle();
      await matchesReviewGolden('goldens/library_search_$mode.png');
    });

    testWidgets('trash — cards and a deck in retention, $mode', (tester) async {
      final repository = FakeTrashRepository(batches: trashAuditBatches());
      addTearDown(repository.dispose);
      await pumpReview(
        tester,
        ReviewApp(
          home: trashScreenWith(repository, const TrashScreen()),
          brightness: brightness,
        ),
      );
      await matchesReviewGolden('goldens/trash_$mode.png');
    });
  }
}
