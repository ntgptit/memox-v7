import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';

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

    testWidgets('opens at rest with the figure line and the CTA, and nothing '
        'else', (tester) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(withDue()),
        screen: const DeckListScreen(),
      );

      // What the collapsed panel says: how much is waiting, how bad it is, and
      // the button that starts it.
      expect(onPanel(find.text('7')), findsWidgets);
      expect(
        onPanel(find.text(english.deckSummaryCardsDueWord)),
        findsOneWidget,
      );
      expect(
        onPanel(find.text(english.deckSummaryStudyDueAction(7))),
        findsOneWidget,
      );

      // What it does not: the resting figures and the learned caption.
      expect(
        onPanel(find.text(english.deckHeroNewMetricWord.toLowerCase())),
        findsNothing,
      );
      expect(
        onPanel(find.text(english.deckHeroScheduledMetricWord.toLowerCase())),
        findsNothing,
      );
      expect(
        onPanel(find.text(english.deckLearnedProgressLabel(40, 160))),
        findsNothing,
      );
    });

    testWidgets('the chevron opens the resting figures and shuts them again', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(withDue()),
        screen: const DeckListScreen(),
      );

      await tester.tap(
        find.bySemanticsLabel(english.deckSummaryExpandLabel).first,
      );
      await tester.pumpAndSettle();

      // 160 cards across the level, 7 due and 9 new, so 144 are resting.
      expect(
        onPanel(find.text(english.deckHeroNewMetricWord.toLowerCase())),
        findsOneWidget,
      );
      expect(onPanel(find.text('144')), findsOneWidget);
      expect(
        onPanel(find.text(english.deckLearnedProgressLabel(40, 160))),
        findsOneWidget,
      );

      await tester.tap(
        find.bySemanticsLabel(english.deckSummaryCollapseLabel).first,
      );
      await tester.pumpAndSettle();

      expect(
        onPanel(find.text(english.deckHeroNewMetricWord.toLowerCase())),
        findsNothing,
      );
      expect(
        onPanel(find.text(english.deckLearnedProgressLabel(40, 160))),
        findsNothing,
      );
    });

    testWidgets(
      'the learned figure waits behind the chevron for every reader',
      (tester) async {
        // **The bar left the resting panel with its caption** (owner review,
        // 2026-08-25). It used to stay as a bare 4px rule, announced but not
        // drawn — which put a screen reader ahead of a sighted user on one
        // figure and left the sighted user a gauge measuring nothing nameable.
        // Now neither gets it until the chevron opens, and both get it whole.
        await pumpDeckScreen(
          tester,
          repository: FakeDeckRepository.withSummaries(withDue()),
          screen: const DeckListScreen(),
        );

        expect(onPanel(find.byType(MxProgressBar)), findsNothing);
        expect(
          onPanel(
            find.bySemanticsLabel(english.deckLearnedProgressLabel(40, 160)),
          ),
          findsNothing,
        );

        await tester.tap(
          find.bySemanticsLabel(english.deckSummaryExpandLabel).first,
        );
        await tester.pumpAndSettle();

        expect(onPanel(find.byType(MxProgressBar)), findsOneWidget);
        expect(
          onPanel(
            find.bySemanticsLabel(english.deckLearnedProgressLabel(40, 160)),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
