import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The hero's metric band, inside a deck (owner mockup, 2026-08-20; compacted
/// 2026-08-25): one numeral answering "how much is waiting", the overdue/today
/// breakdown beside it on the same baseline, New and Scheduled demoted to the
/// quiet context row behind the chevron, and the CTA that starts the study the
/// numeral counted.
///
/// The core fixture is the mandated scenario: A holds B and C; C carries the
/// workload. The panel at A's level folds the child subtrees.
void main() {
  final english = AppLocalizationsEn();

  List<DeckSummary> levelOf({
    required int due,
    required int overdueCards,
    required int overdueDays,
    int newCards = 0,
  }) => <DeckSummary>[
    fakeSummary(id: 'b', name: 'B', totalCardCount: 12, newCardCount: newCards),
    fakeSummary(
      id: 'c',
      name: 'C',
      totalCardCount: 40,
      dueCardCount: due,
      overdueCardCount: overdueCards,
      overdueDayCount: overdueDays,
      learnedCardCount: 10,
    ),
  ];

  Future<void> pumpLevel(
    WidgetTester tester,
    List<DeckSummary> children, {
    Size surface = const Size(393, 852),
    double textScale = 1,
    bool isDark = false,
  }) => pumpDeckScreen(
    tester,
    repository: FakeDeckRepository.withLevel(
      parent: fakeRootDeck(id: 'a', name: 'A'),
      children: children,
    ),
    screen: const DeckListScreen(),
    surface: surface,
    textScale: textScale,
    isDark: isDark,
  );

  Finder onPanel(Finder matching) => find.descendant(
    of: find.byType(DeckLevelSummaryWidget),
    matching: matching,
  );

  /// Opens the resting figures. The panel starts collapsed on every level.
  Future<void> expandSummary(WidgetTester tester) async {
    await tester.tap(
      find.bySemanticsLabel(english.deckSummaryExpandLabel).first,
    );
    await tester.pumpAndSettle();
  }

  /// The hero numeral and its word are separate texts on one baseline row.
  void expectHero(int count, String word) {
    expect(onPanel(find.text('$count')), findsWidgets);
    // The word may also appear in the quiet context row ("New").
    expect(onPanel(find.text(word)), findsWidgets);
  }

  group('the hero metric band (owner mockup, 2026-08-20)', () {
    testWidgets('an overdue subtree folds into the one due numeral, with the '
        'red half on the subline', (tester) async {
      // C: 7 due, all of them from before today, oldest a week old.
      await pumpLevel(tester, levelOf(due: 7, overdueCards: 7, overdueDays: 7));

      expectHero(7, english.deckSummaryCardsDueWord);
      expect(
        onPanel(
          find.textContaining(
            english.deckSummaryOverduePart(7),
            findRichText: true,
          ),
        ),
        findsOneWidget,
        reason: 'the breakdown names the overdue share of the numeral',
      );
      expect(
        onPanel(
          find.textContaining(
            english.deckSummaryDueTodayPart(0),
            findRichText: true,
          ),
        ),
        findsOneWidget,
        reason: 'the split closes: 7 = 7 overdue + 0 today',
      );
    });

    testWidgets('mixed: one numeral, its split, and the quiet context row', (
      tester,
    ) async {
      // C: 40 cards, 15 due of which 12 missed their day; B holds 5 new.
      await pumpLevel(
        tester,
        levelOf(due: 15, overdueCards: 12, overdueDays: 7, newCards: 5),
      );

      expectHero(15, english.deckSummaryCardsDueWord);
      expect(
        onPanel(
          find.textContaining(
            english.deckSummaryOverduePart(12),
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
      expect(
        onPanel(
          find.textContaining(
            english.deckSummaryDueTodayPart(3),
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
      // New and Scheduled keep no semantic ink and no tiles — one quiet row,
      // and it is one chevron away since the compaction.
      // 40 - 15 due - 0 new in C leaves 25 scheduled; B's 12 rows hold 5 new
      // and 7 unscheduled, so the level's resting figure is 32.
      await expandSummary(tester);
      expect(onPanel(find.text('5')), findsWidgets);
      expect(
        onPanel(find.text(english.deckHeroNewMetricWord.toLowerCase())),
        findsWidgets,
      );
      expect(onPanel(find.text('32')), findsOneWidget);
      expect(
        onPanel(find.text(english.deckHeroScheduledMetricWord.toLowerCase())),
        findsOneWidget,
      );
    });

    testWidgets('nothing overdue: no breakdown subline at all', (tester) async {
      await pumpLevel(tester, levelOf(due: 7, overdueCards: 0, overdueDays: 0));

      expectHero(7, english.deckSummaryCardsDueWord);
      expect(
        onPanel(
          find.textContaining(
            english.deckSummaryOverduePart(0),
            findRichText: true,
          ),
        ),
        findsNothing,
        reason: 'with no overdue the subline would repeat the numeral above',
      );
    });

    testWidgets('nothing due: new cards lead the hero instead (BR-150)', (
      tester,
    ) async {
      await pumpLevel(
        tester,
        levelOf(due: 0, overdueCards: 0, overdueDays: 0, newCards: 5),
      );

      expectHero(5, english.deckHeroNewMetricWord);
      expect(
        onPanel(find.byType(MxActionButton)),
        findsNothing,
        reason: 'the CTA counts due cards, and there are none to promise',
      );
    });

    testWidgets('the CTA states the count it starts', (tester) async {
      await pumpLevel(
        tester,
        levelOf(due: 15, overdueCards: 12, overdueDays: 7, newCards: 5),
      );

      expect(
        onPanel(find.text(english.deckSummaryStudyDueAction(15))),
        findsOneWidget,
        reason: 'the button and the numeral count the same fold',
      );
    });

    testWidgets('no eyebrow: the figure line carries its own scope', (
      tester,
    ) async {
      // `TODAY` sat above the numeral as the panel's scope and cost a whole
      // row to say what "cards due" already says (owner review, 2026-08-25).
      // What replaced it in that row is the disclosure, which is the one
      // control the panel has left.
      await pumpLevel(tester, levelOf(due: 7, overdueCards: 0, overdueDays: 0));

      expect(
        onPanel(find.text(english.deckSummaryCardsDueWord)),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(english.deckSummaryExpandLabel),
        findsOneWidget,
      );
    });

    testWidgets('the screen reader hears the numeral, the backlog with its '
        'age, and the context row', (tester) async {
      await pumpLevel(
        tester,
        levelOf(due: 15, overdueCards: 12, overdueDays: 7, newCards: 5),
      );

      expect(
        onPanel(
          find.bySemanticsLabel(english.deckHeroDueTodaySemanticLabel(15)),
        ),
        findsOneWidget,
      );
      expect(
        onPanel(
          find.bySemanticsLabel(english.deckHeroOverdueSemanticLabel(12, 7)),
        ),
        findsOneWidget,
        reason: 'the sentence carries both units: cards and days',
      );
      // The resting figures announce from the context row, so it is opened —
      // a screen reader gets the chevron like anyone else.
      await expandSummary(tester);
      expect(
        onPanel(find.bySemanticsLabel(english.deckHeroNewSemanticLabel(5))),
        findsOneWidget,
      );
      expect(
        onPanel(
          find.bySemanticsLabel(english.deckHeroScheduledSemanticLabel(32)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the learned bar closes the panel once it is opened', (
      tester,
    ) async {
      // It used to sit in the resting panel as an unlabelled rule. A 41% fill
      // between the figure line and the CTA states a proportion of nothing the
      // eye can name, so it went where its caption already was (owner review,
      // 2026-08-25).
      await pumpLevel(
        tester,
        levelOf(due: 15, overdueCards: 12, overdueDays: 7, newCards: 5),
      );

      expect(onPanel(find.byType(MxProgressBar)), findsNothing);

      await expandSummary(tester);
      expect(onPanel(find.byType(MxProgressBar)), findsOneWidget);
    });

    testWidgets('compact width at double scale wraps without overflow', (
      tester,
    ) async {
      await pumpLevel(
        tester,
        levelOf(due: 15, overdueCards: 12, overdueDays: 7, newCards: 46),
        surface: const Size(320, 852),
        textScale: 2,
      );

      // `flutter_test` turns RenderFlex overflow into a failure by itself;
      // reaching these assertions means the layout held.
      expectHero(15, english.deckSummaryCardsDueWord);
      expect(
        onPanel(
          find.textContaining(
            english.deckSummaryOverduePart(12),
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('dark theme renders the same grammar', (tester) async {
      await pumpLevel(
        tester,
        levelOf(due: 7, overdueCards: 7, overdueDays: 7),
        isDark: true,
      );

      expectHero(7, english.deckSummaryCardsDueWord);
      expect(
        onPanel(
          find.textContaining(
            english.deckSummaryOverduePart(7),
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('local midnight ages the backlog sentence with no write '
        'anywhere', (tester) async {
      // The whole path on screen: the controller's midnight tick re-reads,
      // the mapper re-derives the day count from the new `now`, and the
      // panel's screen-reader sentence — the one place the age lives now —
      // moves, while the database has not seen a single write. The fake
      // stands in for the mapper's read-time arithmetic.
      final DateTime start = deckTestNow;
      final DateTime midnight = start.add(const Duration(hours: 5));
      DateTime current = start;
      final repository = FakeDeckRepository(
        deckList: (_) {
          final int days = current.isBefore(midnight) ? 7 : 8;

          return Stream<DeckListSnapshot>.value(
            fakeListSnapshot(
              levelOf(due: 7, overdueCards: 7, overdueDays: days),
              parent: fakeRootDeck(id: 'a', name: 'A'),
              nextOverdueTickAt: current.isBefore(midnight)
                  ? midnight
                  : midnight.add(const Duration(days: 1)),
            ),
          );
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            envConfigProvider.overrideWithValue(EnvConfig.development),
            deckRepositoryProvider.overrideWithValue(repository),
            clockProvider.overrideWithValue(() => current),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildLightTheme(),
            home: const DeckListScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        onPanel(
          find.bySemanticsLabel(english.deckHeroOverdueSemanticLabel(7, 7)),
        ),
        findsOneWidget,
      );

      current = midnight.add(const Duration(seconds: 1));
      await tester.pump(const Duration(hours: 5, minutes: 1));
      await tester.pump();

      expect(
        onPanel(
          find.bySemanticsLabel(english.deckHeroOverdueSemanticLabel(7, 8)),
        ),
        findsOneWidget,
      );
      expect(
        onPanel(
          find.bySemanticsLabel(english.deckHeroOverdueSemanticLabel(7, 7)),
        ),
        findsNothing,
      );
    });
  });

  group('the hero keeps both halves whole', () {
    /// Nothing the renderer had to cut off, among the panel's own text.
    ///
    /// **Clipping is the failure mode here, and it is silent.** Both halves of
    /// the hero were `Flexible`, so a short line shrank *both* and ellipsized
    /// both: `15 cards due  8 overdue · 7 today` drew as `15 car…  8 overdue…`.
    /// No overflow, no exception, every token legal — and BR-162's split, the
    /// whole reason the subline exists, gone from the screen while the
    /// semantics still read it in full.
    List<String> clippedOnPanel(WidgetTester tester) {
      final clipped = <String>[];
      void visit(Element element) {
        final render = element.renderObject;
        if (render is RenderParagraph &&
            render.hasSize &&
            !render.debugNeedsLayout &&
            render.didExceedMaxLines) {
          clipped.add(render.text.toPlainText().trim());
        }
        element.visitChildren(visit);
      }

      tester.element(find.byType(DeckLevelSummaryWidget)).visitChildren(visit);

      // **`scheduled` is excluded, and only that.** The quiet context row
      // clips its unit word at large scales on purpose — "the figure holds,
      // the word clips" is written into `_QuietContextRow`, because half that
      // row is narrower than the word and the count is the fact. That is a
      // decision; the hero's was not.
      // Lower-cased because the row draws them that way: "the word is the
      // unit, the figure is the fact, and a capital gave the two equal
      // billing".
      final quietRowWords = <String>{
        english.deckHeroScheduledMetricWord.toLowerCase(),
        english.deckHeroNewMetricWord.toLowerCase(),
      };

      return clipped.where((text) => !quietRowWords.contains(text)).toList();
    }

    testWidgets('at 360 the subline moves down rather than being cut', (
      tester,
    ) async {
      // 360dp is a common Android width and 1.0 is the default scale, so this
      // is not a stress case — it is what a lot of people see. The line is six
      // pixels short there, which was enough to lose the word `today`.
      await pumpLevel(
        tester,
        levelOf(due: 15, overdueCards: 8, overdueDays: 7),
        surface: const Size(360, 640),
      );
      await expandSummary(tester);

      expect(clippedOnPanel(tester), isEmpty);
      expectHero(15, english.deckSummaryCardsDueWord);
    });

    testWidgets('nothing is cut at 1.3 or 1.5 either', (tester) async {
      for (final scale in <double>[1.3, 1.5]) {
        await pumpLevel(
          tester,
          levelOf(due: 15, overdueCards: 8, overdueDays: 7),
          surface: const Size(360, 640),
          textScale: scale,
        );
        await expandSummary(tester);

        expect(
          clippedOnPanel(tester),
          isEmpty,
          reason: 'the hero clipped at textScaler $scale',
        );
      }
    });

    testWidgets('a line with room for both still draws them side by side', (
      tester,
    ) async {
      // The fix must not cost the wide case its one-line hero: 393 at 1.0 is
      // what the gallery captures, and it fits.
      await pumpLevel(
        tester,
        levelOf(due: 15, overdueCards: 8, overdueDays: 7),
      );
      await expandSummary(tester);

      final numeral = tester.getRect(onPanel(find.text('15')).first);
      final subline = tester.getRect(
        onPanel(find.textContaining(english.deckSummaryOverduePart(8))).first,
      );

      expect(
        subline.left,
        greaterThan(numeral.right),
        reason: 'at 393 the split belongs beside the numeral, not under it',
      );
    });
  });
}
