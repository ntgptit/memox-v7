import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// What "Reset learning progress" calls dangerous, and why it is not the
/// learned count.
///
/// **The two facts come apart, and the row used to read the wrong one.** The
/// risk was fed `learnedCardCount > 0` — a card at box 8 under `eight_box`, or
/// one whose interval reached 128 days under `sm2` (BR-88). Being *studied* is
/// a much earlier event: `firstAnsweredAt` is set by the first answer and is
/// the column the reset transaction clears, documented there as "the only
/// mechanism that does it" (BR-44, BR-13).
///
/// So a deck answered up to box 3 had zero learned cards and a full schedule,
/// and the app gave it an ordinary-looking Reset row over a confirmation
/// promising there was nothing to lose — for the one operation in this feature
/// that has no Trash and no Undo (BR-42, BR-152).
///
/// Case B is what stops the fix from being "mark it always destructive", and
/// Case A is what stops the predicate from going back to the learned count:
/// under the old rule A and B were the same state, so any test that could not
/// tell them apart could not have caught this.
void main() {
  final english = AppLocalizationsEn();

  /// The one root on the list, with the two facts set independently.
  Future<void> pumpRoot(
    WidgetTester tester, {
    required bool isAnswered,
    required int learnedCardCount,
  }) => pumpDeckScreen(
    tester,
    repository: FakeDeckRepository.withSummaries(<DeckSummary>[
      fakeSummary(
        id: 'root-1',
        name: 'Korean',
        totalCardCount: 40,
        dueCardCount: 4,
        learnedCardCount: learnedCardCount,
        firstAnsweredAt: isAnswered ? DateTime.utc(2026, 8) : null,
      ),
    ]),
    screen: const DeckListScreen(),
  );

  Future<void> openRowActions(WidgetTester tester) async {
    await tester.tap(
      find.bySemanticsLabel(RegExp(english.deckActionsSemanticLabel)).last,
    );
    await tester.pumpAndSettle();
  }

  /// Whether the Reset row is inked like Delete, which is always destructive.
  ///
  /// Compared against a sibling rather than against a literal colour: the
  /// question is "does this row wear the destructive treatment", and Delete is
  /// the row that always does. A hardcoded hex would pass just as well on a
  /// palette that had lost the distinction entirely.
  Color inkOf(WidgetTester tester, String label) =>
      tester.widget<Text>(find.text(label)).style!.color!;

  Future<void> openResetConfirm(WidgetTester tester) async {
    await tester.tap(find.text(english.deckResetProgressAction));
    await tester.pumpAndSettle();
  }

  group('a deck that has been studied but has no learned cards', () {
    // The case the old predicate could not see at all.

    testWidgets('the Reset row is inked like Delete', (tester) async {
      await pumpRoot(tester, isAnswered: true, learnedCardCount: 0);
      await openRowActions(tester);

      expect(
        inkOf(tester, english.deckResetProgressAction),
        inkOf(tester, english.deckDeleteAction),
        reason:
            'a reset that discards a schedule is as destructive as a '
            'delete that can be undone for thirty days',
      );
    });

    testWidgets('and the confirmation does not promise nothing is lost', (
      tester,
    ) async {
      await pumpRoot(tester, isAnswered: true, learnedCardCount: 0);
      await openRowActions(tester);
      await openResetConfirm(tester);

      expect(find.text(english.deckResetProgressLostBody), findsOneWidget);
      expect(
        find.text(english.deckResetProgressNothingToLose),
        findsNothing,
        reason: 'the schedule this deck has is exactly what reset throws away',
      );
    });
  });

  group('a deck nobody has answered', () {
    testWidgets('the Reset row is not inked like Delete', (tester) async {
      await pumpRoot(tester, isAnswered: false, learnedCardCount: 0);
      await openRowActions(tester);

      expect(
        inkOf(tester, english.deckResetProgressAction),
        isNot(inkOf(tester, english.deckDeleteAction)),
        reason: 'a red row here would ask the reader to brace for nothing',
      );
    });

    testWidgets('and the confirmation still says there is nothing to lose', (
      tester,
    ) async {
      await pumpRoot(tester, isAnswered: false, learnedCardCount: 0);
      await openRowActions(tester);
      await openResetConfirm(tester);

      expect(find.text(english.deckResetProgressNothingToLose), findsOneWidget);
      expect(find.text(english.deckResetProgressLostBody), findsNothing);
    });
  });

  group('a deck with learned cards', () {
    // Unchanged by the fix, and asserted so the correction cannot be read as
    // "the learned count no longer implies risk". A deck with a learned card
    // has necessarily been answered.
    testWidgets('stays destructive', (tester) async {
      await pumpRoot(tester, isAnswered: true, learnedCardCount: 12);
      await openRowActions(tester);

      expect(
        inkOf(tester, english.deckResetProgressAction),
        inkOf(tester, english.deckDeleteAction),
      );
    });
  });
}
