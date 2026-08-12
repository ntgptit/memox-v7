import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// When the level summary panel is on screen, and who decides.
///
/// Its own file because `deck_list_screen_test.dart` crossed the 400-line guard
/// when the `auto` cases were added to it. The seam is clean: that file owns the
/// screen's four read states and its responsive matrix, this one owns a single
/// piece of view state and the three ways it resolves.
///
/// **Three states, and each one is a different question.** `auto` asks the level;
/// `shown` and `hidden` are the user overriding the answer, in either direction.
/// A test per direction, because the two failures are not symmetric: a panel that
/// re-opens itself where nothing is due is noise, and one that refuses to open
/// where the user asked for it is a broken control.
void main() {
  final english = AppLocalizationsEn();

  /// A level with work waiting on it.
  List<DeckSummary> withDue() => <DeckSummary>[
    fakeSummary(
      id: '1',
      name: 'Japanese N5',
      totalCardCount: 120,
      dueCardCount: 7,
    ),
    fakeSummary(id: '2', name: 'Spanish verbs', totalCardCount: 40),
  ];

  /// A level with cards and none of them due — the case the panel used to
  /// interrupt. Cards rather than an empty deck on purpose: a level with nothing
  /// in it takes the empty state and never reaches this decision.
  List<DeckSummary> caughtUp() => <DeckSummary>[
    fakeSummary(id: '1', name: 'Spanish verbs', totalCardCount: 40),
  ];

  group('the summary panel', () {
    testWidgets('shows itself where something is due', (tester) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(withDue()),
        screen: const DeckListScreen(),
      );

      expect(find.byType(DeckLevelSummaryWidget), findsOneWidget);
      expect(find.text(english.deckSummaryShowAction), findsNothing);
    });

    testWidgets('stays out of the way where nothing is', (tester) async {
      // A panel whose whole content is "nothing is waiting" is a panel that
      // opens to ask for a dismissal. The link stays, so the progress bar inside
      // is one tap away — what goes is having to close something to reach the
      // list.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(caughtUp()),
        screen: const DeckListScreen(),
      );

      expect(find.byType(DeckLevelSummaryWidget), findsNothing);
      expect(find.text(english.deckSummaryShowAction), findsOneWidget);
    });

    testWidgets('hides on request and comes back from the line that replaces it', (
      tester,
    ) async {
      // **Something is always here.** A panel that vanished without trace would
      // leave the user no way back to it and no reason to believe it had been
      // there; the link is what makes dismissing it a preference rather than a
      // loss, so the test walks the whole round trip rather than stopping at
      // "it disappeared".
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(withDue()),
        screen: const DeckListScreen(),
      );

      await tester.tap(
        find.bySemanticsLabel(english.deckSummaryHideLabel).first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(DeckLevelSummaryWidget), findsNothing);
      expect(find.text(english.deckSummaryShowAction), findsOneWidget);

      await tester.tap(find.text(english.deckSummaryShowAction));
      await tester.pumpAndSettle();

      expect(find.byType(DeckLevelSummaryWidget), findsOneWidget);
      expect(find.text(english.deckSummaryShowAction), findsNothing);
    });

    testWidgets('asking for it keeps it, due or not', (tester) async {
      // Once the user has said "show me", the panel stops following the due
      // count. Without that, the link would open a panel that closed itself on
      // the next rebuild.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(caughtUp()),
        screen: const DeckListScreen(),
      );

      await tester.tap(find.text(english.deckSummaryShowAction));
      await tester.pumpAndSettle();

      expect(find.byType(DeckLevelSummaryWidget), findsOneWidget);
      // Metric-first since the anatomy pass: a caught-up level states its two
      // zeroes rather than a sentence (BR-150's no-absence rule).
      expect(
        find.descendant(
          of: find.byType(DeckLevelSummaryWidget),
          matching: find.textContaining(
            '0 ${english.deckHeroDueTodayMetricWord}',
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('dismissing it keeps it dismissed where something is due', (
      tester,
    ) async {
      // The mirror image, and the behaviour that already existed: a level with
      // work waiting does not re-open a panel the user has closed.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(withDue()),
        screen: const DeckListScreen(),
      );

      await tester.tap(
        find.bySemanticsLabel(english.deckSummaryHideLabel).first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(DeckLevelSummaryWidget), findsNothing);
      expect(find.text(english.deckSummaryShowAction), findsOneWidget);
    });
  });
}
