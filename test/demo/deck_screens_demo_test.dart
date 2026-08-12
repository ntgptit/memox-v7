@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import '../features/deck/presentation/support/fake_deck_repository.dart';
import '../support/study_render.dart';
import '../visual_audit/deck_audit_harness.dart';

/// Device-faithful renders of the **real** deck list, for a human to look at.
///
/// **The gap this closes.** `design_preview/goldens/deck_list_*.png` is a
/// hand-built mock that predates the toolbar, the summary panel and the
/// breadcrumb, so the screen that actually ships had no picture of itself. That
/// is why the chip-weight change of M4.11f turned three *card* goldens red and
/// nothing on the deck side: there was nothing there to turn.
///
/// Mounted through the production router with the database faked, exactly as
/// `deck_list_screen_visual_audit_test.dart` does — so what is captured is the
/// screen rather than a drawing of it, bottom bar included.
///
/// **Both levels, because one screen does two jobs.** The root heads itself
/// "Your decks" and lists roots; a level inside a deck adds the breadcrumb, heads
/// itself "Sub-decks", and resolves its scheduler through the root. A regression
/// that only shows in the nested case now has somewhere to appear.
///
/// Counts are chosen to cover the three foot states the card can be in — due,
/// nothing due, and fully learned — rather than to look tidy.
void main() {
  List<DeckSummary> roots() => <DeckSummary>[
    fakeSummary(
      id: 'd1',
      name: 'Academic Word List',
      totalCardCount: 570,
      newCardCount: 46,
      dueCardCount: 12,
      // A week behind on eight of the twelve: the hero splits the total into
      // 8 Overdue + 4 Due today (BR-162), and the day badge is the age of
      // the oldest card (BR-161).
      overdueCardCount: 8,
      overdueDayCount: 7,
      learnedCardCount: 120,
      subDeckCount: 4,
    ),
    fakeSummary(
      id: 'd2',
      name: 'IELTS Writing Task 2',
      totalCardCount: 210,
      dueCardCount: 3,
      learnedCardCount: 145,
      subDeckCount: 2,
      schedulerType: SchedulerType.sm2,
    ),
    fakeSummary(
      id: 'd3',
      name: 'Phrasal verbs',
      totalCardCount: 88,
      learnedCardCount: 88,
      subDeckCount: 1,
    ),
    fakeSummary(id: 'd4', name: 'Business email', subDeckCount: 3),
  ];

  /// The states the density pass and BR-150 added: an empty production
  /// library offering its two ways in, and a new-only deck keeping its Study.
  List<DeckSummary> newOnly() => <DeckSummary>[
    fakeSummary(
      id: 'd1',
      name: 'Korean vocabulary',
      totalCardCount: 20,
      newCardCount: 20,
      subDeckCount: 2,
    ),
  ];

  for (final (String mode, Brightness brightness) in <(String, Brightness)>[
    ('light', Brightness.light),
    ('dark', Brightness.dark),
  ]) {
    testWidgets('deck list — root level, $mode', (tester) async {
      await pumpReview(
        tester,
        ReviewApp(
          home: deckShellWith(FakeDeckRepository.withSummaries(roots())),
          brightness: brightness,
        ),
      );

      await matchesReviewGolden('goldens/deck_list_root_$mode.png');
    });

    testWidgets('deck list — inside a deck, $mode', (tester) async {
      // Level 3, so the breadcrumb has something to say: it is hidden at levels
      // 1-2, where Back and the Decks tab already answer "where am I".
      //
      // `ancestors` is the chain **above** the parent and never includes it —
      // the parent is the title, and the breadcrumb's last step is drawn from
      // it. Repeating it here renders the name twice.
      final repo = FakeDeckRepository.withLevel(
        parent: fakeSubDeck(id: 'd1a', name: 'Sublist 1', parentId: 'd1'),
        ancestors: <DeckPathSegment>[
          const DeckPathSegment(id: 'd1', name: 'Academic Word List'),
        ],
        children: <DeckSummary>[
          fakeChildSummary(
            id: 'd1a1',
            name: 'Nouns',
            parentId: 'd1a',
            totalCardCount: 60,
            newCardCount: 14,
            dueCardCount: 7,
            overdueCardCount: 4,
            overdueDayCount: 1,
            learnedCardCount: 22,
          ),
          fakeChildSummary(
            id: 'd1a2',
            name: 'Verbs',
            parentId: 'd1a',
            totalCardCount: 60,
            learnedCardCount: 60,
          ),
          fakeChildSummary(
            id: 'd1a3',
            name: 'Adjectives',
            parentId: 'd1a',
            totalCardCount: 60,
            dueCardCount: 5,
            subDeckCount: 2,
          ),
        ],
      );

      await pumpReview(
        tester,
        ReviewApp(home: deckLevelWith(repo), brightness: brightness),
      );

      await matchesReviewGolden('goldens/deck_list_level_$mode.png');
    });

    testWidgets('deck list — empty library, $mode', (tester) async {
      // The production first-run: nothing seeded, two ways forward (UC-01).
      await pumpReview(
        tester,
        ReviewApp(
          home: deckShellWith(FakeDeckRepository()),
          brightness: brightness,
        ),
      );

      await matchesReviewGolden('goldens/deck_list_empty_$mode.png');
    });

    testWidgets('deck list — new-only deck keeps Study, $mode', (tester) async {
      // BR-150's poster case: twenty unlearned cards, nothing due, and the
      // Study button present anyway.
      await pumpReview(
        tester,
        ReviewApp(
          home: deckShellWith(FakeDeckRepository.withSummaries(newOnly())),
          brightness: brightness,
        ),
      );

      await matchesReviewGolden('goldens/deck_list_new_only_$mode.png');
    });
  }
}
