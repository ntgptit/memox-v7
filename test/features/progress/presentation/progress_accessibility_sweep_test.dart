import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/presentation/screens/progress_deck_screen.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_streak_hero_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_summary_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_today_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_week_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_section_label.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_level_fixtures.dart';
import 'support/progress_screen_harness.dart';

/// Progress under the heading grammar every other feature already speaks
/// (SC-C5-03).
///
/// **Progress was the last feature drawing its own group titles**: hand-set
/// `labelLarge` in sentence case, with no `header` node anywhere on the tab. So
/// a screen reader could not jump between the sections at all — the one
/// affordance a section heading exists to provide — and the tab was visually
/// the odd one out in a four-tab shell. All four now go through
/// `MxSectionLabel`.
///
/// **The hero is the deliberate exception, and it is asserted as one.** The
/// panel is a single composed node (`progress_streak_hero_widget.dart`): read
/// as separate nodes it announces "7", "days", "3 cards today" — three
/// fragments in which the figure has lost what it measures. Its heading
/// therefore sits inside the panel's `ExcludeSemantics` and contributes no
/// header node of its own. Asserting that explicitly is the point: without it,
/// the next person to count headings on this screen finds three where the
/// component was used four times and "fixes" the wrong one.
void main() {
  final english = AppLocalizationsEn();

  /// The section's own heading node — the label, not the panel around it.
  SemanticsNode headingOf(WidgetTester tester, Type section) =>
      tester.getSemantics(
        find.descendant(
          of: find.byType(section),
          matching: find.byType(MxSectionLabel),
        ),
      );

  void expectHeading(WidgetTester tester, Type section, String sentence) {
    final SemanticsNode node = headingOf(tester, section);

    // The caps are a paint-time treatment; the sentence the ARB wrote is what
    // a reader is given, and the node is a header so it can be jumped to.
    expect(node.flagsCollection.isHeader, isTrue, reason: '$section');
    expect(node.label, sentence, reason: '$section');
    expect(
      find.descendant(
        of: find.byType(section),
        matching: find.text(sentence.toUpperCase()),
      ),
      findsOneWidget,
      reason: '$section',
    );
  }

  Future<void> pumpOverview(WidgetTester tester) async {
    await pumpProgressScreen(
      tester,
      repository: FakeProgressRepository(
        initial: progressOverviewFixture(
          totals: const <int>[12, 0, 6, 143, 3, 9, 8],
          streakDays: 5,
          today: DateTime.utc(2026, 8, 12),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the overview headings announce as headings, in the written '
      'sentence rather than the painted caps', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpOverview(tester);

    expectHeading(
      tester,
      ProgressTodayWidget,
      english.progressTodaySectionLabel,
    );
    expectHeading(tester, ProgressWeekWidget, english.progressWeekSectionLabel);

    handle.dispose();
  });

  testWidgets('the streak hero stays one merged node, not a heading', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpOverview(tester);

    // It uses the component like its three siblings — the caps and the rung
    // are the point of the change — but the panel's own `ExcludeSemantics`
    // swallows the label's node, so `getSemantics` from the label resolves to
    // the panel's single composed node instead. That is the assertion: one
    // sentence, and it is not a heading.
    final SemanticsNode node = headingOf(tester, ProgressStreakHeroWidget);

    expect(node.flagsCollection.isHeader, isFalse);
    expect(node.label, contains(english.progressStreakSemanticsHeadline(5)));
    expect(node.label, isNot(english.progressStreakSectionLabel));

    handle.dispose();
  });

  testWidgets('the totals panel on the deck level announces as a heading too', (
    tester,
  ) async {
    // The fourth call site, and the one on the other Progress surface: the
    // by-deck level's summary panel. Swept here rather than left to the
    // geometry file because what it needed is the same thing — a heading that
    // names a group and can be jumped to.
    final handle = tester.ensureSemantics();
    await pumpProgressScreen(
      tester,
      repository: level(),
      screen: const ProgressDeckScreen(),
    );
    await tester.pumpAndSettle();

    expectHeading(
      tester,
      ProgressSummaryWidget,
      english.progressSummaryLast7DaysTitle,
    );

    handle.dispose();
  });
}
