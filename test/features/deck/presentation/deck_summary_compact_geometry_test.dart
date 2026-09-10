import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_summary_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The share of the viewport the hero is allowed to occupy, as a fraction.
///
/// Named because the assertion below reads as a rule and not as arithmetic:
/// what is held is "no more than this much of the screen", and the division is
/// how that is measured rather than what it means.
const double heroViewportCeiling = 0.22;

/// How much of the screen the hero takes, and how much of the list that leaves.
///
/// **The defect this locks was reported as a picture, not as a value.** The
/// panel answered four questions at once and stood 320px tall on a 393x852
/// device — 37.6% of the viewport — which left one deck card whole above the
/// bottom bar and half of a second. It is 140px and 16.4% now, and three cards
/// are whole. Every number involved was a legitimate token; the bug lived in
/// the *sum* of five stacked bands, so only geometry after layout can see it.
/// `getRect`, therefore, and not a widget finder.
///
/// **`pumpDeckApp`, not `pumpDeckScreen`, and the difference is 80px.** The
/// screen on its own has 852px to spend; the app has 772, because the bottom
/// navigation bar covers the rest. An earlier pass measured without the shell,
/// read three whole cards off it, and was wrong on a device by exactly that
/// bar — the kind of confidently wrong figure the gallery rule exists to
/// prevent. Three is true here because the fold is where the bar starts.
void main() {
  /// The owner's reported figures: 15 due of which 8 missed their day, 46 new
  /// across 868 cards.
  List<DeckSummary> reportedLibrary() => <DeckSummary>[
    fakeSummary(
      id: '1',
      name: 'Academic Word List',
      totalCardCount: 570,
      newCardCount: 46,
      dueCardCount: 12,
      overdueCardCount: 8,
      overdueDayCount: 3,
      learnedCardCount: 120,
      subDeckCount: 4,
    ),
    fakeSummary(
      id: '2',
      name: 'IELTS Writing Task 2',
      totalCardCount: 210,
      dueCardCount: 3,
      learnedCardCount: 145,
      subDeckCount: 2,
    ),
    fakeSummary(
      id: '3',
      name: 'Phrasal verbs',
      totalCardCount: 88,
      learnedCardCount: 88,
      subDeckCount: 1,
    ),
    fakeSummary(id: '4', name: 'Business email', totalCardCount: 40),
  ];

  /// The surface actually rendered, read back rather than restated.
  ///
  /// The harness sets the view; a test that divided by its own copy of 852
  /// would keep reporting a percentage of a screen it was no longer measuring
  /// the moment that default moved.
  Size viewportOf(WidgetTester tester) =>
      tester.view.physicalSize / tester.view.devicePixelRatio;

  /// Where the list actually stops being readable: the top of the bottom bar,
  /// not the bottom of the window.
  double foldOf(WidgetTester tester) =>
      tester.getRect(find.byType(MxNavigationBar)).top;

  testWidgets('the hero takes no more than 22% of the viewport', (
    tester,
  ) async {
    await pumpDeckApp(
      tester,
      repository: FakeDeckRepository.withSummaries(reportedLibrary()),
    );

    final height = tester.getRect(find.byType(DeckLevelSummaryWidget)).height;
    final viewport = viewportOf(tester);

    expect(
      height / viewport.height,
      lessThanOrEqualTo(heroViewportCeiling),
      reason:
          'the hero measured ${height.toStringAsFixed(0)}px of '
          '${viewport.height.toStringAsFixed(0)} — the screen belongs to the '
          'list under it',
    );
  });

  testWidgets('three deck cards are whole above the bottom bar', (
    tester,
  ) async {
    // **Three, and the 16px that bought the third one has changed hands.**
    // The first pass reached two whole cards and 89% of a third: the hero was
    // at its floor and the chrome had given back all it had. Folding the
    // learned bar away (owner review, 2026-08-25) returned the bar plus its
    // `md` gap — exactly the 16 the third card was short.
    //
    // The bar came back to rest on 2026-09-10 and the third card survived,
    // because the root's CTA left in the same change: a button plus its gap is
    // 56px against the bar's 16, so the panel is net shorter than it was even
    // with the fold. The target was never blocked by the hero's floor; it was
    // blocked by what the panel chose to carry.
    await pumpDeckApp(
      tester,
      repository: FakeDeckRepository.withSummaries(reportedLibrary()),
    );

    final fold = foldOf(tester);
    final tiles = find.byType(DeckTileWidget);
    final rects = List<Rect>.generate(
      tiles.evaluate().length,
      (i) => tester.getRect(tiles.at(i)),
    );

    expect(
      rects.where((r) => r.bottom <= fold).length,
      greaterThanOrEqualTo(3),
      reason: 'three deck cards must be readable end to end without scrolling',
    );
  });

  testWidgets('the root panel is two bands, and a third has to come past '
      'this test', (tester) async {
    // **This replaces a test about the disclosure**, which measured that the
    // chevron revealed something and gave the height back. There is no
    // chevron: the fold's whole payload was one repeat of the numeral above it
    // and two zeros, so it was managing a volume the deck rows already carry.
    //
    // What the old test was really holding is the panel's height discipline,
    // and the two tests above hold that in pixels. This one holds the cause
    // rather than the symptom: every band on this panel costs a slice of the
    // list, so the composition is stated outright — the figure line, the level
    // bar, and nothing else at the root. A fourth band cannot arrive by
    // passing a percentage that happens to still fit.
    await pumpDeckApp(
      tester,
      repository: FakeDeckRepository.withSummaries(reportedLibrary()),
    );

    Finder onPanel(Finder matching) => find.descendant(
      of: find.byType(DeckLevelSummaryWidget),
      matching: matching,
    );

    expect(onPanel(find.byType(MxProgressBar)), findsOneWidget);
    expect(
      onPanel(find.byType(MxActionButton)),
      findsNothing,
      reason:
          'the root cannot start a session (BR-101), so it offers no CTA — '
          'and the 56px that button cost is what the level bar now spends',
    );
    expect(
      onPanel(find.byType(MxIconButton)),
      findsNothing,
      reason: 'the panel states its facts; it has no control of its own',
    );
  });
}
