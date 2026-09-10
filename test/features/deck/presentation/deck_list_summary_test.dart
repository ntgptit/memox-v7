import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/mx_hero_card.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// When the level summary panel is on screen, how much of it, and how much
/// room that leaves the list underneath.
///
/// Its own file because `deck_list_screen_test.dart` crossed the 400-line guard
/// when these cases were added to it. The seam is clean: that file owns the
/// screen's four read states and its responsive matrix, this one owns the
/// panel's own presence and its disclosure.
///
/// **The panel used to be dismissible and is not** (owner decision,
/// 2026-08-25). The three-state visibility choice — `auto`, `shown`, `hidden` —
/// and the one-line link that brought a dismissed panel back are both gone. The
/// reason the panel was dismissible was that it stood at 37.6% of the viewport
/// and was in the way of the list; the compaction removed the reason, and the
/// chevron it used to own now opens the resting figures instead. What survives
/// of the old behaviour is the rule `auto` already followed: a level with work
/// waiting gets the panel, a level without gets the list.
void main() {
  final english = AppLocalizationsEn();

  /// A level with work waiting on it.
  List<DeckSummary> withDue() => <DeckSummary>[
    fakeSummary(
      id: '1',
      name: 'Japanese N5',
      totalCardCount: 120,
      dueCardCount: 7,
      overdueCardCount: 3,
      overdueDayCount: 2,
      newCardCount: 9,
      learnedCardCount: 40,
    ),
    fakeSummary(id: '2', name: 'Spanish verbs', totalCardCount: 40),
  ];

  /// A level with cards and none of them due — the case the panel used to
  /// interrupt. Cards rather than an empty deck on purpose: a level with nothing
  /// in it takes the empty state and never reaches this decision.
  List<DeckSummary> caughtUp() => <DeckSummary>[
    fakeSummary(
      id: '1',
      name: 'Spanish verbs',
      totalCardCount: 40,
      learnedCardCount: 40,
    ),
  ];

  Finder onPanel(Finder matching) => find.descendant(
    of: find.byType(DeckLevelSummaryWidget),
    matching: matching,
  );

  group('the hero CTA names what it actually does', () {
    // **One level runs it now.** Inside a deck the button opens that deck's
    // session (BR-101: one root, one session). At the root it could only open
    // the Study tab — a list with nothing started — so it was relabelled to
    // say so, and then removed: a filled hero pointing at the outlined verbs
    // below it inverted the screen's hierarchy, and the row's own Study is the
    // honest way to pick a deck. The label was the whole promise; the fix was
    // to stop making one the screen could not keep.

    testWidgets('the root offers no hero, because it opens no session', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(withDue()),
        screen: const DeckListScreen(),
      );

      expect(
        onPanel(find.byType(MxHeroPrimary)),
        findsNothing,
        reason: 'the root cannot start a session, so it must not offer to',
      );
      expect(
        onPanel(find.text(english.deckSummaryStudyDueAction(7))),
        findsNothing,
      );
    });

    testWidgets('the row keeps the verb the panel gave up', (tester) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(withDue()),
        screen: const DeckListScreen(),
      );

      // Removing the hero only reads as a simplification if what it pointed at
      // is still there. It is, once per deck with something to study.
      expect(find.text(english.deckStudyAction), findsWidgets);
    });

    testWidgets('a deck level still promises the session it starts', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withLevel(
          parent: fakeRootDeck(id: 'a', name: 'A'),
          children: withDue(),
        ),
        screen: const DeckListScreen(),
      );

      // The counterpart, and the reason the root case was removed rather than
      // the button: here the promise is one the screen can keep, so it stays.
      expect(
        onPanel(find.text(english.deckSummaryStudyDueAction(7))),
        findsOneWidget,
      );
    });
  });

  group('the summary panel', () {
    testWidgets('shows itself where something is due', (tester) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(withDue()),
        screen: const DeckListScreen(),
      );

      expect(find.byType(DeckLevelSummaryWidget), findsOneWidget);
    });

    testWidgets('stays out of the way where nothing is', (tester) async {
      // A panel whose whole content is "nothing is waiting" is a panel that
      // opens to ask for a dismissal. Nothing stands in for it now: the deck
      // cards below carry their own progress bars, so a caught-up level loses
      // no figure by not printing this one.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(caughtUp()),
        screen: const DeckListScreen(),
      );

      expect(find.byType(DeckLevelSummaryWidget), findsNothing);
      expect(find.byType(DeckTileWidget), findsOneWidget);
    });

    testWidgets('states the workload and the level progress, and nothing '
        'else', (tester) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(withDue()),
        screen: const DeckListScreen(),
      );

      // What the collapsed panel says: how much is waiting, how bad it is, and
      // the button that acts on it.
      expect(onPanel(find.text('7')), findsWidgets);
      expect(
        onPanel(find.text(english.deckSummaryCardsDueWord)),
        findsOneWidget,
      );
      // **And no button, because at the root there is no session to start.**
      // A session belongs to one root deck (BR-101), so the panel states the
      // workload and stops; the deck that gets studied is chosen on its own
      // row, where the verb now carries the emphasis this hero used to hold.
      expect(
        onPanel(find.text(english.deckSummaryStudyDueAction(7))),
        findsNothing,
        reason: 'the deck-level promise must not appear at the root',
      );

      // **What it does not carry: New and Scheduled.** Not folded away — gone.
      // `new` is a chip on every deck row below, and `scheduled` counts the one
      // thing this screen cannot act on.
      expect(
        onPanel(find.text(english.deckHeroNewMetricWord.toLowerCase())),
        findsNothing,
      );
      expect(
        onPanel(find.text(english.deckHeroScheduledMetricWord.toLowerCase())),
        findsNothing,
      );

      // **And what it does carry, without being asked: the level's progress.**
      // 160 cards across the level, 40 of them learned. This is the one figure
      // the rows cannot state between them — each row's bar measures its own
      // deck, none of them measures the level.
      expect(
        onPanel(find.text(english.deckLearnedProgressLabel(40, 160))),
        findsOneWidget,
      );
    });

    testWidgets('the panel has no control of its own', (tester) async {
      // **This replaces a test that opened and shut a disclosure.** The panel
      // was dismissible, then foldable; both controls existed because the panel
      // was in the way of the list, and at two facts it is not. A chevron whose
      // whole payload was one repeat of the number above it and two zeros was
      // managing a volume the deck rows already carry.
      //
      // Asserted as "no button at all" rather than "no chevron": the point is
      // that nothing here is tappable, so re-growing a different control has to
      // come past this test rather than past a label match.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(withDue()),
        screen: const DeckListScreen(),
      );

      expect(onPanel(find.byType(MxIconButton)), findsNothing);
      expect(
        onPanel(find.byType(InkWell)),
        findsNothing,
        reason: 'the panel states two facts; nothing on it is a control',
      );
    });

    testWidgets('the learned figure reaches every reader at rest', (
      tester,
    ) async {
      // **The bar left the resting panel with its caption** (owner review,
      // 2026-08-25) and came back with it (2026-09-10). What it must never
      // be again is either half alone: a bare 4px rule announced but not
      // drawn put a screen reader ahead of a sighted user, and a fold took
      // the figure away from both. Drawn and announced, or not present.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(withDue()),
        screen: const DeckListScreen(),
      );

      expect(onPanel(find.byType(MxProgressBar)), findsOneWidget);
      expect(
        onPanel(
          find.bySemanticsLabel(english.deckLearnedProgressLabel(40, 160)),
        ),
        findsOneWidget,
      );
    });
  });
}
