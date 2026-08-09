import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_entry_summary_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_mode_chooser_widget.dart';

import '../../features/study/presentation/support/study_widget_harness.dart';

/// `HOST-WIDGET` for BR-100 — the presentation half of IT-STUDY-006.
///
/// **BR-99 is already covered; this is the other half of the same screen.**
/// BR-99 says a mode with no data is disabled and explained, and
/// `study_entry_widget_test.dart` proves that for all three data reasons. BR-100
/// governs what the copy is *not* allowed to say, and a prohibition is invisible
/// to every test that only checks what is shown.
///
/// The rule: the way out is real, and that is exactly why it must not be
/// offered. The algorithm locks after the first `scheduled` turn (BR-13) and
/// only Reset learning progress unlocks it — and Reset throws away every card's
/// schedule (BR-41). A subtitle reading "reset the deck to use this mode" is a
/// correct instruction that trades away something the user never meant to
/// trade, in a sentence they read while trying to pick a study mode.
///
/// Nothing here fails loudly if it regresses. A future copy change adds one
/// helpful line, every other test still passes, and the damage arrives as a
/// user who reset a deck they had studied for three months.
void main() {
  const eightBoxModes = <StudyMode>[
    StudyMode.match,
    StudyMode.guess,
    StudyMode.recall,
    StudyMode.fill,
  ];

  /// The copy BR-100 forbids on this surface, in the forms it would take.
  ///
  /// Matched case-insensitively on the rendered text rather than on an ARB key,
  /// because the failure being prevented is a *new* sentence written at this
  /// call site — which by definition has a key nobody has thought of yet.
  const forbidden = <String>['reset', 'learning progress'];

  StudyEntrySummaryModel summaryOf({
    int newCount = 3,
    int dueCount = 6,
    int fillableCount = 2,
    int distinctMeanings = 6,
  }) => StudyEntrySummaryModel(
    newCount: newCount,
    dueCount: dueCount,
    fillableCount: fillableCount,
    distinctMeanings: distinctMeanings,
  );

  Future<void> pumpChooser(
    WidgetTester tester, {
    required List<StudyMode> modes,
    required StudyEntrySummaryModel summary,
  }) => tester.pumpWidget(
    wrapForTest(
      StudyModeChooserWidget(
        modes: modes,
        summary: summary,
        onModeSelected: (_) {},
      ),
    ),
  );

  /// Every string the chooser actually put on screen.
  List<String> renderedText(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => (text.data ?? text.textSpan?.toPlainText() ?? ''))
      .where((value) => value.isNotEmpty)
      .toList();

  void expectNoResetOffer(WidgetTester tester) {
    final lowered = renderedText(tester).map((v) => v.toLowerCase()).toList();

    for (final phrase in forbidden) {
      expect(
        lowered.where((value) => value.contains(phrase)),
        isEmpty,
        reason:
            'BR-100: "$phrase" on the mode chooser is an offer to trade the '
            "deck's whole schedule for one screen — the rendered lines were "
            '$lowered',
      );
    }
  }

  testWidgets('IT-STUDY-006 · a blocked mode explains the data it needs and '
      'nothing more (BR-100)', (tester) async {
    // All three data reasons at once, so a single run covers every unavailable
    // subtitle the widget can produce.
    await pumpChooser(
      tester,
      modes: eightBoxModes,
      summary: summaryOf(dueCount: 1, fillableCount: 0, distinctMeanings: 1),
    );

    expect(find.text('Needs cards with an example'), findsOneWidget);
    expect(find.text('Needs five different meanings'), findsOneWidget);
    expect(find.text('Needs at least two pairs'), findsOneWidget);
    expectNoResetOffer(tester);
  });

  testWidgets('IT-STUDY-006 · an sm2 deck is never shown the four graded modes '
      'at all (BR-100, BR-146)', (tester) async {
    // A mode the *algorithm* refuses is not a mode waiting for more cards, so
    // it does not appear as a disabled row either — a row saying "not available
    // for this deck" is the sentence a reader answers with "how do I make it
    // available?", and the only true answer is the one BR-100 forbids.
    await pumpChooser(
      tester,
      modes: const <StudyMode>[StudyMode.selfAssess],
      summary: summaryOf(),
    );

    for (final label in <String>['Match', 'Guess', 'Recall', 'Fill in']) {
      expect(
        find.text(label),
        findsNothing,
        reason: '$label is eight_box only',
      );
    }
    expectNoResetOffer(tester);
  });
}
