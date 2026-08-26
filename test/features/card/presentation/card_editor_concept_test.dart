import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_action_bar_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

import 'support/card_editor_harness.dart';
import 'support/fake_card_repository.dart';

/// What `Save changes` owns, and what leaving the editor costs (UC-04 A1).
///
/// Split from the layout half at the 400-line guard, and the seam is a real
/// one: this file is about commands and state, the other is about what is on
/// screen and where.
void main() {
  Finder footerSave() => find.descendant(
    of: find.byType(CardEditorActionBarWidget),
    matching: find.widgetWithText(MxActionButton, 'Save changes'),
  );

  Finder shortcutSave() => find.widgetWithText(MxActionButton, 'Save');

  bool isEnabled(WidgetTester tester, Finder finder) =>
      tester.widget<MxActionButton>(finder).onPressed != null;

  FakeCardRepository seed() {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card(
      'card-1',
      front: 'old front',
      back: 'old back',
    );

    return repository;
  }

  group('two Save affordances, one command', () {
    testWidgets('both are inert on a pristine form', (tester) async {
      await pumpCardEditor(tester, seed());

      expect(isEnabled(tester, footerSave()), isFalse);
      expect(isEnabled(tester, shortcutSave()), isFalse);
    });

    testWidgets('both wake on the same keystroke', (tester) async {
      await pumpCardEditor(tester, seed());

      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();

      expect(isEnabled(tester, footerSave()), isTrue);
      expect(isEnabled(tester, shortcutSave()), isTrue);
    });

    testWidgets('the shortcut writes once, through the same path', (
      tester,
    ) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);

      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();
      await tester.tap(shortcutSave());
      await tester.pumpAndSettle();

      expect(repository.updates.single.front, 'new front');
      expect(find.text('deck detail'), findsOneWidget);
    });

    testWidgets('editing back to the original value puts both to sleep', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());

      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();
      // Not an undo: the same text typed again. Dirty is a comparison against
      // the loaded card, so retyping the original lands back on pristine.
      await tester.enterText(find.byType(TextField).first, 'old front');
      await tester.pump();

      expect(isEnabled(tester, footerSave()), isFalse);
      expect(isEnabled(tester, shortcutSave()), isFalse);
    });

    testWidgets('trailing whitespace alone is not a change', (tester) async {
      await pumpCardEditor(tester, seed());

      // A save would trim it, so the row written would be identical.
      await tester.enterText(find.byType(TextField).first, 'old front   ');
      await tester.pump();

      expect(isEnabled(tester, footerSave()), isFalse);
    });

    testWidgets('only the footer carries the spinner', (tester) async {
      final repository = seed();
      final gate = Completer<void>();
      repository.updateGate = gate;
      await pumpCardEditor(tester, repository);

      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();
      await tester.tap(footerSave());
      await tester.pump();

      // Two spinners for one operation is two operations to the person
      // watching. The shortcut simply goes inert.
      expect(
        find.descendant(
          of: find.byType(CardEditorActionBarWidget),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(isEnabled(tester, shortcutSave()), isFalse);

      gate.complete();
      await tester.pumpAndSettle();
      expect(repository.updates, hasLength(1));
    });
  });

  group('tags and the flag are not Save\'s', () {
    testWidgets('a committed tag leaves Save asleep', (tester) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);

      final field = await openTagEntry(tester);
      await tester.enterText(field, 'noun');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pumpAndSettle();

      expect(repository.tagAdds.single.name, 'noun');
      expect(isEnabled(tester, footerSave()), isFalse);
    });

    testWidgets('a committed flag leaves Save asleep', (tester) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      expect(repository.flagWrites, hasLength(1));
      expect(isEnabled(tester, footerSave()), isFalse);
    });

    testWidgets('an uncommitted tag draft leaves Save asleep', (tester) async {
      await pumpCardEditor(tester, seed());

      final field = await openTagEntry(tester);
      await tester.enterText(field, 'nou');
      await tester.pump();

      expect(isEnabled(tester, footerSave()), isFalse);
    });
  });

  group('one way out', () {
    testWidgets('a pristine form leaves with no question asked', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('deck detail'), findsOneWidget);
    });

    testWidgets('back arrow, Cancel and the gesture ask the same question', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());
      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();

      for (final Finder affordance in <Finder>[
        find.byIcon(Icons.arrow_back),
        find.descendant(
          of: find.byType(CardEditorActionBarWidget),
          matching: find.text('Cancel'),
        ),
      ]) {
        await tester.tap(affordance);
        await tester.pumpAndSettle();
        expect(find.text('Discard changes?'), findsOneWidget);
        await tester.tap(find.text('Keep editing'));
        await tester.pumpAndSettle();
      }

      await pressSystemBack(tester);
      expect(find.text('Discard changes?'), findsOneWidget);
    });

    testWidgets('Keep editing leaves the draft exactly as it was', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());
      await tester.enterText(find.byType(TextField).first, 'half typed');
      await tester.pump();

      await pressSystemBack(tester);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();

      expect(find.text('half typed'), findsOneWidget);
      expect(find.text('deck detail'), findsNothing);
      expect(isEnabled(tester, footerSave()), isTrue);
    });

    testWidgets('back twice in a row opens one dialog, not two', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());
      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();

      await pressSystemBackTwice(tester);

      expect(find.text('Discard changes?'), findsOneWidget);
    });

    testWidgets('an uncommitted tag draft is worth asking about', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());

      final field = await openTagEntry(tester);
      await tester.enterText(field, 'nou');
      await tester.pump();
      await pressSystemBack(tester);

      expect(find.text('Discard changes?'), findsOneWidget);
    });

    testWidgets('closing the entry keeps the draft, and the guard with it', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());

      final field = await openTagEntry(tester);
      await tester.enterText(field, 'nou');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Dismissing the entry is not a discard: the text is still work the user
      // would lose, so the question still gets asked.
      await pressSystemBack(tester);
      expect(find.text('Discard changes?'), findsOneWidget);
    });

    testWidgets('a successful save leaves without asking to discard', (
      tester,
    ) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);

      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();
      await tester.tap(footerSave());
      await tester.pumpAndSettle();

      // The guard must not swallow the screen's own exit: the whole point of
      // `canPop: false` is that something has to let this through.
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('deck detail'), findsOneWidget);
    });

    testWidgets('a failed save keeps the text, the screen and the dirty flag', (
      tester,
    ) async {
      final repository = seed();
      repository.nextCreateFailure = const DatabaseFailure(message: 'nope');
      await pumpCardEditor(tester, repository);

      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();
      await tester.tap(footerSave());
      await tester.pumpAndSettle();

      expect(find.text('deck detail'), findsNothing);
      expect(find.text('new front'), findsOneWidget);
      expect(isEnabled(tester, footerSave()), isTrue);
    });

    testWidgets('leaving is inert while a save is in flight', (tester) async {
      final repository = seed();
      final gate = Completer<void>();
      repository.updateGate = gate;
      await pumpCardEditor(tester, repository);

      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();
      await tester.tap(footerSave());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      // Neither exit: a pop would land the write on a screen that is gone, and
      // a discard dialog would offer to throw away work already being written.
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('deck detail'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(repository.updates, hasLength(1));
    });

    testWidgets('a pristine form lets the platform run its own back', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());

      expect(
        tester.widget<PopScope<Object?>>(find.byType(PopScope<Object?>)).canPop,
        isTrue,
      );

      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();

      expect(
        tester.widget<PopScope<Object?>>(find.byType(PopScope<Object?>)).canPop,
        isFalse,
      );
    });
  });
}
