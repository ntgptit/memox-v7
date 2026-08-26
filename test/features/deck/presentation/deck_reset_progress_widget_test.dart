import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_reset_progress_widget.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The Reset learning progress confirmation (UC-07, BR-50).
///
/// **BR-50 is a rule about a screen, so it is checked on the screen.** It asks
/// for both lists — what is kept and what is lost — and the reason it is a rule
/// at all is that a destructive action described by only one of them reads as
/// safer than it is.
void main() {
  DeckEntity root({SchedulerType scheduler = SchedulerType.eightBox}) =>
      DeckEntity(
        id: 'root',
        name: 'Korean',
        parentDeckId: null,
        rootDeckId: 'root',
        contentType: DeckContentType.deck,
        schedulerType: scheduler,
        schedulerGeneration: 1,
        firstAnsweredAt: DateTime.utc(2026),
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );

  Future<FakeDeckRepository> pumpSheet(
    WidgetTester tester, {
    required bool hasLearnedCards,
    SchedulerType scheduler = SchedulerType.eightBox,
  }) async {
    final repository = FakeDeckRepository();

    await pumpDeckScreen(
      tester,
      repository: repository,
      screen: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDeckResetProgressConfirm(
            context,
            deck: root(scheduler: scheduler),
            hasLearnedCards: hasLearnedCards,
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    return repository;
  }

  testWidgets('it states both what is kept and what is lost (BR-50)', (
    tester,
  ) async {
    await pumpSheet(tester, hasLearnedCards: true);

    expect(find.text('Kept'), findsOneWidget);
    expect(find.textContaining('past review history'), findsOneWidget);
    expect(find.text('Lost'), findsOneWidget);
    // The consequence people miss: the cards do not merely become due, they
    // walk the whole learning chain again (BR-142, BR-42).
    expect(find.textContaining('go back to New'), findsOneWidget);
  });

  testWidgets('a deck nobody has studied says so instead (A2)', (tester) async {
    // Still allowed — it is how the study mode is changed — and a list of
    // losses would be a warning about nothing.
    await pumpSheet(tester, hasLearnedCards: false);

    expect(find.text('Kept'), findsOneWidget);
    expect(find.textContaining('no progress to lose'), findsOneWidget);
    expect(find.textContaining('go back to New'), findsNothing);
  });

  testWidgets('the picker starts on the mode the deck already runs', (
    tester,
  ) async {
    // UC-07 A1: confirming without touching it is a plain reset, not an
    // accidental change of algorithm.
    final repository = await pumpSheet(
      tester,
      hasLearnedCards: true,
      scheduler: SchedulerType.sm2,
    );

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(repository.progressResets, hasLength(1));
    expect(repository.progressResets.single.schedulerType, SchedulerType.sm2);
    expect(repository.progressResets.single.rootDeckId, 'root');
  });

  testWidgets('choosing another mode is what the reset carries', (
    tester,
  ) async {
    // BR-44: this is the only way to change it once a card has been learned,
    // which is why the picker lives inside the confirmation (UC-07 step 3).
    final repository = await pumpSheet(tester, hasLearnedCards: true);

    await tester.tap(find.text('SM-2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(repository.progressResets.single.schedulerType, SchedulerType.sm2);
  });

  testWidgets('the lock warning is absent — this is what undoes the lock', (
    tester,
  ) async {
    // The create form shows it because the choice is about to lock. Repeating
    // it here would warn about the state being left rather than the one being
    // entered (BR-44).
    await pumpSheet(tester, hasLearnedCards: true);

    expect(find.textContaining('locks after the first review'), findsNothing);
  });

  testWidgets('cancelling writes nothing', (tester) async {
    final repository = await pumpSheet(tester, hasLearnedCards: true);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.progressResets, isEmpty);
  });

  testWidgets('the mode section is titled once, by this sheet', (tester) async {
    // This sheet titles the section `Study mode after the reset`; the picker
    // used to add `Study mode` directly under it, so the sheet read as two
    // headings stacked with nothing between them.
    await pumpSheet(tester, hasLearnedCards: true);

    expect(find.text('Study mode after the reset'), findsOneWidget);
    expect(find.text('Study mode'), findsNothing);
  });
}
