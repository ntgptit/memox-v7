import 'package:flutter/material.dart';
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
import 'package:memox/features/deck/presentation/widgets/items/deck_overdue_badge_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The hero's three disjoint sets, inside a deck (BR-162): descending into A
/// keeps the level's own breakdown on the panel — Overdue, Due today, New —
/// and the `+Nd` badge stays pinned to the overdue metric.
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

  Finder metric(int count, String word) =>
      onPanel(find.textContaining('$count $word', findRichText: true));

  group('the hero breakdown inside a deck (BR-162)', () {
    testWidgets('an overdue subtree keeps its cards and its days on the '
        'panel', (tester) async {
      // C: 7 due, all of them from before today, oldest a week old.
      await pumpLevel(tester, levelOf(due: 7, overdueCards: 7, overdueDays: 7));

      expect(
        metric(7, english.deckHeroOverdueAgedMetricWord(7)),
        findsOneWidget,
        reason:
            'the backlog count, with the age in words beside the set '
            'name — no chip in the hero',
      );
      expect(metric(0, english.deckHeroDueTodayMetricWord), findsOneWidget);
      expect(onPanel(find.byType(DeckOverdueBadgeWidget)), findsNothing);
      expect(onPanel(find.byIcon(Icons.event_busy)), findsOneWidget);
    });

    testWidgets('mixed: the four sets are four figures', (tester) async {
      // C: 40 cards, 15 due → 25 scheduled ahead; B holds 12 unscheduled
      // rows with no due cards, so the level's fourth figure is 25 + 12.
      await pumpLevel(
        tester,
        levelOf(due: 15, overdueCards: 12, overdueDays: 7, newCards: 5),
      );

      expect(
        metric(12, english.deckHeroOverdueAgedMetricWord(7)),
        findsOneWidget,
      );
      expect(metric(3, english.deckHeroDueTodayMetricWord), findsOneWidget);
      expect(metric(5, english.deckHeroNewMetricWord), findsOneWidget);
      expect(
        metric(32, english.deckHeroScheduledMetricWord),
        findsOneWidget,
        reason: 'the resting set closes the partition to the level total',
      );
    });

    testWidgets('one day is already the overdue state', (tester) async {
      await pumpLevel(tester, levelOf(due: 3, overdueCards: 3, overdueDays: 1));

      expect(
        metric(3, english.deckHeroOverdueAgedMetricWord(1)),
        findsOneWidget,
      );
    });

    testWidgets('a long backlog caps at 99+', (tester) async {
      await pumpLevel(
        tester,
        levelOf(due: 3, overdueCards: 3, overdueDays: 120),
      );

      expect(
        metric(3, english.deckHeroOverdueAgedCapMetricWord),
        findsOneWidget,
      );
      expect(
        metric(3, english.deckHeroOverdueAgedMetricWord(120)),
        findsNothing,
      );
    });

    testWidgets('due today: filled calendar on, no badge anywhere', (
      tester,
    ) async {
      await pumpLevel(tester, levelOf(due: 7, overdueCards: 0, overdueDays: 0));

      expect(metric(0, english.deckHeroOverdueMetricWord), findsOneWidget);
      expect(metric(7, english.deckHeroDueTodayMetricWord), findsOneWidget);
      expect(onPanel(find.byIcon(Icons.event)), findsOneWidget);
      expect(onPanel(find.byType(DeckOverdueBadgeWidget)), findsNothing);
    });

    testWidgets('nothing due: three anchors still stand, all quiet', (
      tester,
    ) async {
      // Every metric keeps its icon anchor at zero — the shape is the
      // metric's identity — and the due-today calendar rests outlined.
      await pumpLevel(
        tester,
        levelOf(due: 0, overdueCards: 0, overdueDays: 0, newCards: 5),
      );

      expect(onPanel(find.byIcon(Icons.event_busy)), findsOneWidget);
      expect(onPanel(find.byIcon(Icons.event_outlined)), findsOneWidget);
      expect(onPanel(find.byIcon(Icons.auto_awesome_outlined)), findsOneWidget);
      expect(
        onPanel(find.byIcon(Icons.event_available_outlined)),
        findsOneWidget,
      );
      expect(onPanel(find.byType(DeckOverdueBadgeWidget)), findsNothing);
    });

    testWidgets('the eyebrow scopes the panel to today', (tester) async {
      await pumpLevel(tester, levelOf(due: 7, overdueCards: 0, overdueDays: 0));

      expect(onPanel(find.text(english.deckSummaryTodayLabel)), findsOneWidget);
    });

    testWidgets('the screen reader hears three sentences, each once', (
      tester,
    ) async {
      await pumpLevel(
        tester,
        levelOf(due: 15, overdueCards: 12, overdueDays: 7, newCards: 5),
      );

      expect(
        onPanel(
          find.bySemanticsLabel(english.deckHeroOverdueSemanticLabel(12, 7)),
        ),
        findsOneWidget,
        reason: 'the sentence carries both units: cards and days',
      );
      expect(
        onPanel(
          find.bySemanticsLabel(english.deckHeroDueTodaySemanticLabel(3)),
        ),
        findsOneWidget,
      );
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

    testWidgets('the numerals of each row share one baseline', (tester) async {
      // Row one mixes type roles on purpose — a primary `headlineMedium`
      // beside a supporting `titleLarge` — and a top-aligned row would hang
      // the taller line box's baseline below its neighbour's. The grid rows
      // align on the alphabetic baseline instead, and this measures the
      // rendered result rather than trusting the flag.
      double baselineOf(int count, String word) {
        final finder = metric(count, word);
        final rich = tester.widget<RichText>(finder);
        final box = tester.renderObject<RenderBox>(finder);
        final painter = TextPainter(
          text: rich.text,
          textDirection: TextDirection.ltr,
          textScaler: rich.textScaler,
        )..layout(maxWidth: box.size.width);
        final metrics = painter.computeLineMetrics().first;

        return tester.getTopLeft(finder).dy + metrics.baseline;
      }

      await pumpLevel(
        tester,
        levelOf(due: 15, overdueCards: 12, overdueDays: 7, newCards: 5),
      );

      expect(
        (baselineOf(12, english.deckHeroOverdueAgedMetricWord(7)) -
                baselineOf(3, english.deckHeroDueTodayMetricWord))
            .abs(),
        lessThanOrEqualTo(0.5),
        reason: 'primary and supporting numerals sit on one baseline',
      );
      expect(
        (baselineOf(5, english.deckHeroNewMetricWord) -
                baselineOf(32, english.deckHeroScheduledMetricWord))
            .abs(),
        lessThanOrEqualTo(0.5),
      );
    });

    testWidgets('the grid keeps two aligned columns even with the aged word', (
      tester,
    ) async {
      // The regression this pins: the overdue cell used to size itself around
      // a chip, so the second column of its row started further right than
      // the second column of the row below. Fixed-width cells align them.
      await pumpLevel(
        tester,
        levelOf(due: 15, overdueCards: 12, overdueDays: 7, newCards: 5),
      );

      expect(onPanel(find.byType(MxProgressBar)), findsOneWidget);
      final dueTodayLeft = tester
          .getTopLeft(metric(3, english.deckHeroDueTodayMetricWord))
          .dx;
      final scheduledLeft = tester
          .getTopLeft(metric(32, english.deckHeroScheduledMetricWord))
          .dx;
      expect(
        dueTodayLeft,
        scheduledLeft,
        reason: 'the right column shares one left edge across both rows',
      );
      final overdueLeft = tester
          .getTopLeft(metric(12, english.deckHeroOverdueAgedMetricWord(7)))
          .dx;
      final newLeft = tester
          .getTopLeft(metric(5, english.deckHeroNewMetricWord))
          .dx;
      expect(overdueLeft, newLeft);
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
      // reaching these assertions means the wrapped layout held, with every
      // figure still on screen.
      expect(
        metric(12, english.deckHeroOverdueAgedMetricWord(7)),
        findsOneWidget,
      );
      expect(metric(3, english.deckHeroDueTodayMetricWord), findsOneWidget);
      expect(metric(46, english.deckHeroNewMetricWord), findsOneWidget);
    });

    testWidgets('dark theme renders the same grammar', (tester) async {
      await pumpLevel(
        tester,
        levelOf(due: 7, overdueCards: 7, overdueDays: 7),
        isDark: true,
      );

      expect(
        metric(7, english.deckHeroOverdueAgedMetricWord(7)),
        findsOneWidget,
      );
      expect(onPanel(find.byIcon(Icons.event_busy)), findsOneWidget);
    });

    testWidgets('local midnight turns +7d into +8d with no write anywhere', (
      tester,
    ) async {
      // The whole path on screen: the controller's midnight tick re-reads,
      // the mapper re-derives day count and partition from the new `now`,
      // and the panel's badge moves — while the database has not seen a
      // single write. The fake stands in for the mapper's read-time
      // arithmetic: what it serves depends only on the clock it is read at.
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

      // Before the boundary: the tile's chip and the panel's worded age
      // agree on seven days.
      expect(find.text(english.deckOverdueBadgeLabel(7)), findsOneWidget);
      expect(
        metric(7, english.deckHeroOverdueAgedMetricWord(7)),
        findsOneWidget,
      );

      current = midnight.add(const Duration(seconds: 1));
      await tester.pump(const Duration(hours: 5, minutes: 1));
      await tester.pump();

      expect(find.text(english.deckOverdueBadgeLabel(8)), findsOneWidget);
      expect(
        metric(7, english.deckHeroOverdueAgedMetricWord(8)),
        findsOneWidget,
      );
      expect(find.text(english.deckOverdueBadgeLabel(7)), findsNothing);
    });
  });
}
