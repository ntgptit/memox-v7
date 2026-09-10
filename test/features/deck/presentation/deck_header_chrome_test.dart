import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_subheader_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The Library header's chrome, after the 2026-09-10 layout pass.
///
/// Two things arrived together and only one of them is decoration.
void main() {
  final english = AppLocalizationsEn();

  List<DeckSummary> withDue() => <DeckSummary>[
    fakeSummary(
      id: 'd1',
      name: 'Japanese N5',
      totalCardCount: 120,
      dueCardCount: 7,
      learnedCardCount: 30,
    ),
  ];

  List<DeckSummary> caughtUp() => <DeckSummary>[
    fakeSummary(
      id: 'd1',
      name: 'Japanese N5',
      totalCardCount: 120,
      learnedCardCount: 120,
    ),
  ];

  Future<void> pump(WidgetTester tester, List<DeckSummary> decks) =>
      pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(decks),
        screen: const DeckListScreen(),
      );

  Finder dot() => find.descendant(
    of: find.byType(DeckSubheaderWidget),
    matching: find.bySemanticsLabel(english.deckHeaderReadySemanticLabel),
  );

  group('the status dot earns its place', () {
    // **The reference draws one unconditionally and this one does not**, which
    // is the whole difference between a decoration and a fact. A mark that is
    // always present says nothing; spent on the one thing the line beside it
    // cannot say — whether any of those cards is waiting — it says something no
    // count on this screen says.

    testWidgets('present where something is waiting', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, withDue());

      expect(dot(), findsOneWidget);
      handle.dispose();
    });

    testWidgets('absent on a level that is caught up', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, caughtUp());

      expect(
        dot(),
        findsNothing,
        reason: 'a dot that is always there is a dot that means nothing',
      );
      handle.dispose();
    });

    testWidgets('announced, not merely coloured', (tester) async {
      // Colour alone reaches neither a screen reader nor a reader who cannot
      // separate this green from this grey. The finder above matches on the
      // semantics label rather than on a `Container`, so this whole group
      // fails the day the sentence is dropped and only the paint is left.
      final handle = tester.ensureSemantics();
      await pump(tester, withDue());

      expect(
        find.bySemanticsLabel(english.deckHeaderReadySemanticLabel),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  testWidgets('the bar actions are plain, not outlined', (tester) async {
    // **Reversed on the device.** The 2026-09-10 mockup drew these as outlined
    // circles and the screen was built that way; seen rendered, the owner
    // asked for the edge back off. This asserts the reversal held rather than
    // asserting a shape the screen no longer wants — a copy-pasted assertion
    // for `.outlined` would have quietly proven the wrong thing green.
    await pump(tester, withDue());

    final outlined = tester
        .widgetList<MxIconButton>(find.byType(MxIconButton))
        .where((MxIconButton b) => b.shape == MxIconButtonShape.outlined);

    expect(
      outlined,
      isEmpty,
      reason: 'the bar actions read plain again — search and the overflow menu',
    );
  });
}
