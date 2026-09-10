import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/fallback/route_not_found_screen.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/core/time/delay_provider.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/search/di/library_search_repository_provider.dart';
import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/card/presentation/screens/card_import_screen.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/card/presentation/screens/tag_catalog_screen.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/di/deck_template_provider.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_template_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/presentation/screens/starter_library_screen.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/reminder/di/reminder_settings_repository_provider.dart';
import 'package:memox/features/reminder/presentation/screens/reminder_settings_screen.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/features/study/presentation/screens/study_options_screen.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';

import '../features/card/presentation/support/fake_card_detail_repository.dart';
import '../features/card/presentation/support/fake_card_repository.dart';
import '../features/card/presentation/support/fake_tag_catalog_repository.dart';
import '../features/deck/presentation/support/fake_deck_repository.dart';
import '../features/progress/presentation/support/fake_progress_repository.dart';
import '../features/reminder/support/fake_reminder_platform.dart';
import '../features/search/presentation/support/fake_library_search_repository.dart';
import '../features/search/presentation/support/search_screen_harness.dart';
import '../features/settings/domain/support/fake_app_settings_repository.dart';
import '../features/study/domain/support/fake_study_home_repository.dart';
import '../features/study/domain/support/fake_study_repository.dart';
import '../features/trash/presentation/support/fake_trash_repository.dart';
import '../support/study_render.dart';
import '../visual_audit/card_audit_harness.dart';
import '../visual_audit/deck_audit_harness.dart';
import '../visual_audit/progress_audit_harness.dart';
import '../visual_audit/settings_audit_harness.dart';
import '../visual_audit/study_audit_harness.dart';
import '../visual_audit/trash_audit_harness.dart';

/// Every production screen, laid out sideways.
///
/// **A phone rotated, not a tablet imagined.** 852 x 393 is the app's own
/// golden surface turned ninety degrees — the shape a user produces by tilting
/// the device they already have. All 333 committed goldens are 393 x 852, and
/// `mx_responsive_test.dart` was the only landscape test in the repo, covering
/// a synthetic composition of shared widgets rather than any screen. The app
/// had exactly one orientation under test.
///
/// **A floor, not a picture.** This asserts the two things a screen must not do
/// at any width — throw while laying out, and shrink a target below the touch
/// floor — and deliberately asserts nothing about appearance. How the screens
/// *look* sideways is a golden's job, and CLAUDE.md keeps the gallery at one
/// surface on purpose: a render at another width sitting beside the others
/// reads as a screen that got narrower, and `build_screen_gallery.py` fails the
/// build for adding one.
///
/// **What is actually at risk here.** The reading column reached all seventeen
/// screens in M100.50, so width above 600 is capped and centred rather than
/// stretched. What is left is the vertical axis: 393 of height is under half
/// the portrait figure, and a column that fitted comfortably has far less room
/// to do it in.
void main() {
  /// The portrait golden surface, rotated.
  const Size landscape = Size(852, 393);

  /// One screen, and the state it is swept in.
  ///
  /// Loaded states wherever the fake offers one in a single call — an empty
  /// screen has little to overflow, so a sweep of empties is a test that cannot
  /// fail. Where the harness default *is* the interesting state — a form, a
  /// wizard's first step — that is what is used.
  final screens = <({String name, Widget Function() build})>[
    (
      name: 'deck list',
      // The deck harness hands back a bare `Router`, not an app — its own
      // audit gets the `MaterialApp` from the audit runner.
      build: () => ReviewApp(home: deckShellWith(FakeDeckRepository())),
    ),
    (
      name: 'card list',
      build: () => ReviewApp(
        home: cardScreenWith(
          FakeCardRepository.loaded(<CardListItemModel>[
            FakeCardRepository().listItem(
              'c1',
              front: 'apple',
              back: 'qua tao',
              isFlagged: true,
              tagNames: <String>['noun', 'food'],
            ),
          ]),
          const CardListScreen(deckId: 'deck-1'),
        ),
      ),
    ),
    (
      name: 'card detail',
      build: () => ReviewApp(
        home: cardDetailScreenWith(
          FakeCardDetailRepository(),
          const CardDetailScreen(deckId: 'deck-1', cardId: 'card-1'),
        ),
      ),
    ),
    (
      name: 'card editor',
      build: () => ReviewApp(
        home: cardScreenWith(
          FakeCardRepository(),
          const CardEditorScreen(deckId: 'deck-1'),
        ),
      ),
    ),
    (
      name: 'card import',
      build: () => ReviewApp(
        home: cardScreenWith(
          FakeCardRepository(),
          const CardImportScreen(deckId: 'deck-1'),
        ),
      ),
    ),
    (
      name: 'tag catalog',
      build: () => ReviewApp(
        home: tagScreenWith(
          FakeTagCatalogRepository.seeded(const <TagCatalogEntry>[
            TagCatalogEntry(id: 't1', name: 'noun', cardCount: 12, linkedCardCount: 12),
            TagCatalogEntry(id: 't2', name: 'food', cardCount: 3, linkedCardCount: 3),
          ]),
          const TagCatalogScreen(),
        ),
      ),
    ),
    (
      name: 'library search',
      // Built here rather than pulled from a harness: the search screen's own
      // audit declares this scope inline too, and the overrides are what make
      // the screen resolvable at all.
      build: () => ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          librarySearchRepositoryProvider.overrideWithValue(
            FakeLibrarySearchRepository.serving(fakeSearchPage()),
          ),
          delaySchedulerProvider.overrideWithValue(immediateScheduler),
        ],
        child: const ReviewApp(home: LibrarySearchScreen()),
      ),
    ),
    (
      name: 'settings',
      build: () => ReviewApp(
        home: settingsScreenWith(
          FakeAppSettingsRepository(),
          const SettingsScreen(),
        ),
      ),
    ),
    (
      name: 'reminder settings',
      build: () => ProviderScope(
        overrides: [
          reminderSettingsRepositoryProvider.overrideWithValue(
            FakeReminderSettings(),
          ),
        ],
        child: const ReviewApp(home: ReminderSettingsScreen()),
      ),
    ),
    (
      name: 'trash',
      build: () => ReviewApp(
        home: trashScreenWith(
          FakeTrashRepository(batches: trashAuditBatches()),
          const TrashScreen(),
        ),
      ),
    ),
    (name: 'progress', build: () => ReviewApp(home: progressScreenWith())),
    (
      name: 'study home',
      build: () => ReviewApp(
        home: studyHomeScreenWith(
          FakeStudyHomeRepository(initial: fakeStudyHome()),
          const StudyHomeScreen(),
        ),
      ),
    ),
    (
      name: 'study entry',
      build: () => ReviewApp(
        home: studyScreenWith(
          FakeStudyRepository(),
          const StudyEntryScreen(
            deckId: 'deck-1',
            optionsRouteName: RouteNames.deckStudyOptions,
            homeRouteName: RouteNames.study,
          ),
        ),
      ),
    ),
    (
      name: 'study options',
      build: () => ReviewApp(
        home: studyScreenWith(
          FakeStudyRepository(),
          const StudyOptionsScreen(deckId: 'deck-1'),
        ),
      ),
    ),
    (
      name: 'study session',
      build: () => ReviewApp(
        home: studyScreenWith(
          FakeStudyRepository(),
          const StudySessionScreen(
            deckId: 'deck-1',
            kind: StudySessionKind.reviewing,
            reviewMode: StudyMode.selfAssess,
          ),
        ),
      ),
    ),
    (
      name: 'starter library',
      // The one screen reached through the real router rather than mounted
      // directly: it is a branch of the deck shell, and the catalogue it lists
      // comes from a provider rather than a repository.
      build: () => ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          deckTemplateCatalogProvider.overrideWith(
            (ref) async => <DeckTemplate>[
              DeckTemplate(
                templateId: 'starter-1',
                version: 1,
                locale: 'en',
                title: DeckName.parse('Everyday English').name!,
                contentSource: 'memox-fixture',
                defaultSchedulerType: SchedulerType.eightBox,
                children: const <DeckTemplateNode>[],
              ),
            ],
          ),
        ],
        child: const ReviewApp(home: StarterLibraryScreen()),
      ),
    ),
    (
      name: 'progress by deck',
      build: () => ReviewApp(
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
              ],
            ),
          ),
        ),
      ),
    ),
    (
      name: 'route not found',
      build: () => const ReviewApp(home: RouteNotFoundScreen()),
    ),
  ];

  for (final screen in screens) {
    testWidgets('${screen.name} lays out at 852x393', (tester) async {
      final handle = tester.ensureSemantics();
      // **Pumped, not settled, and that is the design.** This measures layout,
      // and a tree does not have to be still to be laid out. Two of these
      // screens hold a repeating animation open — a progress indicator is the
      // usual one — so `pumpAndSettle` runs to its timeout and reports a hang
      // that is really a spinner doing its job. Requiring quiescence would test
      // the fakes rather than the screens.
      //
      // Fixed pumps rather than a settle: a constant duration is every bit as
      // deterministic, and 400ms is past every entrance this app runs.
      await pumpReview(
        tester,
        screen.build(),
        surface: landscape,
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Taken here rather than left to surface on its own: an overflow
      // reported during a later pump is attributed to whichever test happens to
      // be running then, which is how a layout error becomes somebody else's
      // flake.
      expect(
        tester.takeException(),
        isNull,
        reason: '${screen.name} threw while laying out sideways',
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

      // **Restored here, not in a tearDown.** `pumpReview` turns shadows on so
      // a golden shows real depth and leaves the caller to put it back —
      // `matchesReviewGolden` is what normally does. A `tearDown` runs *after*
      // the framework's paint-vars invariant, so every case in this file failed
      // for a reason that had nothing to do with layout until this moved into
      // the body.
      debugDisableShadows = true;
      handle.dispose();
    });
  }
}
