import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_conflict_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_scheduler_change_widget.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The study-mode sheet of UC-03: the unlocked change, and the locked
/// explanation that replaces it.
///
/// **The distinction every test here is drawing is "which operation did the
/// screen actually call".** Both write a scheduler and both re-seed the tree,
/// but only one spends a generation and destroys a cycle. A sheet that wired the
/// wrong one would look identical until a user's history went missing, which is
/// why the fake keeps two separate lists.
void main() {
  DeckEntity deck({
    bool isRoot = true,
    bool isLocked = false,
    SchedulerType scheduler = SchedulerType.eightBox,
  }) => DeckEntity(
    id: isRoot ? 'root' : 'child',
    name: isRoot ? 'Korean' : 'Chapter 1',
    parentDeckId: isRoot ? null : 'root',
    rootDeckId: 'root',
    contentType: DeckContentType.deck,
    schedulerType: isRoot ? scheduler : null,
    schedulerGeneration: isRoot ? 1 : null,
    firstAnsweredAt: isLocked ? DateTime.utc(2026) : null,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  Future<FakeDeckRepository> pumpSheet(
    WidgetTester tester, {
    bool isLocked = false,
    SchedulerType scheduler = SchedulerType.eightBox,
  }) async {
    final repository = FakeDeckRepository();

    await pumpDeckScreen(
      tester,
      repository: repository,
      screen: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDeckSchedulerSheet(
            context,
            deck: deck(isLocked: isLocked, scheduler: scheduler),
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    return repository;
  }

  group('an unlocked root', () {
    testWidgets('the picker starts on the mode the deck already runs', (
      tester,
    ) async {
      // Never null. A radio group opening empty reads as "you have not chosen
      // yet" on a deck that chose at creation (BR-11).
      final repository = await pumpSheet(tester, scheduler: SchedulerType.sm2);

      await tester.tap(find.text('Change study mode').last);
      await tester.pumpAndSettle();

      expect(repository.schedulerChanges, hasLength(1));
      expect(
        repository.schedulerChanges.single.schedulerType,
        SchedulerType.sm2,
      );
      expect(repository.schedulerChanges.single.rootDeckId, 'root');
    });

    testWidgets('choosing another mode is what the change carries', (
      tester,
    ) async {
      final repository = await pumpSheet(tester);

      await tester.tap(find.text('SM-2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change study mode').last);
      await tester.pumpAndSettle();

      expect(
        repository.schedulerChanges.single.schedulerType,
        SchedulerType.sm2,
      );
    });

    testWidgets('it never calls the destructive reset', (tester) async {
      // The bug this exists to catch: routing BR-12's change through UC-07
      // would spend a generation and mark an empty history as superseded, on a
      // deck where there is nothing to reset.
      final repository = await pumpSheet(tester);

      await tester.tap(find.text('Change study mode').last);
      await tester.pumpAndSettle();

      expect(repository.progressResets, isEmpty);
    });

    testWidgets('it says the tree restarts and the content does not', (
      tester,
    ) async {
      // BR-14 in the user's words, and no second list of losses: nothing is
      // being taken away, so borrowing Reset's warning would ask them to brace
      // for something that is not happening.
      await pumpSheet(tester);

      expect(find.textContaining('starts its schedule again'), findsOneWidget);
      expect(
        find.textContaining('cards, tags and notes all stay'),
        findsOneWidget,
      );
      expect(find.text('Lost'), findsNothing);
    });

    testWidgets('it warns that an open session will be closed', (tester) async {
      await pumpSheet(tester);

      expect(find.textContaining('will be closed'), findsOneWidget);
    });

    testWidgets('a lock landing mid-sheet routes to Reset (UC-03 E4)', (
      tester,
    ) async {
      // The race: the sheet was drawn against an unlocked deck and a card
      // finished the chain before the user confirmed. Retrying can only fail
      // the same way, so the confirm gives way to the one action that still
      // works — an error line on its own would make this the only state with no
      // way forward.
      final repository = await pumpSheet(tester);
      repository.writeFailure = const ConflictFailure(
        message: 'locked',
        reason: DeckConflictReason.schedulerLocked,
      );

      await tester.tap(find.text('Change study mode').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('already studied this deck'), findsOneWidget);
      expect(find.text('Reset learning progress'), findsOneWidget);
      expect(find.text('Change study mode'), findsNothing);
    });

    testWidgets('another refusal keeps the confirm, so a retry is possible', (
      tester,
    ) async {
      // Only the lock is a dead end. A database error is worth trying again,
      // and swapping the button for Reset there would offer a destructive
      // operation as the answer to a transient one.
      final repository = await pumpSheet(tester);
      repository.writeFailure = const DatabaseFailure(message: 'disk');

      await tester.tap(find.text('Change study mode').last);
      await tester.pumpAndSettle();

      expect(find.text('Reset learning progress'), findsNothing);
      expect(find.text('Change study mode'), findsOneWidget);
    });

    testWidgets('cancelling writes nothing', (tester) async {
      final repository = await pumpSheet(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.schedulerChanges, isEmpty);
      expect(repository.progressResets, isEmpty);
    });
  });

  group('a locked root', () {
    testWidgets('explains the lock instead of offering the change', (
      tester,
    ) async {
      // UC-03 A1: the section stays. Hiding it makes a user believe the app
      // cannot change study mode at all.
      await pumpSheet(tester, isLocked: true);

      expect(find.text('Study mode is locked'), findsOneWidget);
      expect(
        find.textContaining('Resetting learning progress'),
        findsOneWidget,
      );
      expect(find.text('Change study mode'), findsNothing);
    });

    testWidgets('shows which mode is locked in, disabled', (tester) async {
      // Which algorithm the deck runs is still what the user came to find out,
      // and an empty locked panel does not answer it.
      await pumpSheet(tester, isLocked: true, scheduler: SchedulerType.sm2);

      final tile = tester.widget<RadioListTile<SchedulerType>>(
        find
            .byType(RadioListTile<SchedulerType>)
            .at(SchedulerType.values.indexOf(SchedulerType.sm2) - 1),
      );
      expect(tile.enabled, isFalse);
    });

    testWidgets('offers Reset learning progress as the way through', (
      tester,
    ) async {
      // BR-44 is the only mechanism, so the sheet that reports the lock is
      // where the route to it belongs.
      await pumpSheet(tester, isLocked: true);

      expect(find.text('Reset learning progress'), findsOneWidget);
    });
  });
}
