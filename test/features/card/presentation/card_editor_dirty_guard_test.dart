import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/entities/tag_entity.dart';
import 'package:memox/features/card/domain/failures/tag_validation_failure.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_action_bar_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

import 'support/card_editor_harness.dart';
import 'support/fake_card_repository.dart';

/// What `Save changes` owns, and what leaving the editor costs (UC-04 A1).
///
/// **Two questions the old editor could not answer.** Save was always
/// pressable, so it said nothing about whether there was anything to save; and
/// nothing stood between a stray back gesture and a form full of typing.
void main() {
  Finder saveButton() => find.widgetWithText(MxActionButton, 'Save changes');

  bool isSaveEnabled(WidgetTester tester) =>
      tester.widget<MxActionButton>(saveButton()).onPressed != null;

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

  group('the save button tracks the five content fields', () {
    testWidgets('a pristine form cannot be saved', (tester) async {
      await pumpCardEditor(tester, seed());

      expect(isSaveEnabled(tester), isFalse);
    });

    testWidgets('typing in the front enables it', (tester) async {
      await pumpCardEditor(tester, seed());

      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();

      expect(isSaveEnabled(tester), isTrue);
    });

    testWidgets('typing in an optional detail enables it', (tester) async {
      await pumpCardEditor(tester, seed());

      await tester.ensureVisible(find.text(kDetailsToggleLabel));
      await tester.tap(find.text(kDetailsToggleLabel));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Example'),
        'an example',
      );
      await tester.pump();

      expect(isSaveEnabled(tester), isTrue);
    });

    testWidgets('editing back to the original value disables it again', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());

      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();
      expect(isSaveEnabled(tester), isTrue);

      // Not an undo: the same text typed again. Dirty is a comparison against
      // the loaded card, so retyping the original lands back on pristine —
      // which a has-been-edited flag could never do.
      await tester.enterText(find.byType(TextField).first, 'old front');
      await tester.pump();

      expect(isSaveEnabled(tester), isFalse);
    });

    testWidgets('trailing whitespace alone is not a change', (tester) async {
      await pumpCardEditor(tester, seed());

      // A save would trim it, so the row written would be identical.
      await tester.enterText(find.byType(TextField).first, 'old front   ');
      await tester.pump();

      expect(isSaveEnabled(tester), isFalse);
    });

    testWidgets('opening the details disclosure is not a change', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());

      await tester.ensureVisible(find.text(kDetailsToggleLabel));
      await tester.tap(find.text(kDetailsToggleLabel));
      await tester.pumpAndSettle();

      expect(isSaveEnabled(tester), isFalse);
    });

    testWidgets('a committed tag does not enable it', (tester) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);

      await tester.enterText(tagInput(), 'noun');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(repository.tagAdds.single.name, 'noun');
      // Tags write the moment they are added (BR-93). A Save lit by one would
      // be offering to write something it does not carry.
      expect(isSaveEnabled(tester), isFalse);
    });

    testWidgets('a committed flag does not enable it', (tester) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      expect(repository.flagWrites, hasLength(1));
      expect(isSaveEnabled(tester), isFalse);
    });

    testWidgets('an uncommitted tag draft does not enable it', (tester) async {
      await pumpCardEditor(tester, seed());

      await tester.enterText(tagInput(), 'nou');
      await tester.pump();

      expect(isSaveEnabled(tester), isFalse);
    });
  });

  group('leaving the editor', () {
    testWidgets('a pristine form lets the platform run its own back', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());

      // **`canPop` tracks the draft.** A screen that claims the gesture
      // unconditionally suppresses Android's predictive-back preview even when
      // it is going to allow the pop anyway.
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

    testWidgets('a pristine form leaves immediately, with no question asked', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('deck detail'), findsOneWidget);
    });

    testWidgets('the close button and the system back ask the same question', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());
      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();

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
      expect(isSaveEnabled(tester), isTrue);
    });

    testWidgets('Discard leaves once, and the write never happened', (
      tester,
    ) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);
      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();

      await pressSystemBack(tester);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('deck detail'), findsOneWidget);
      expect(repository.updates, isEmpty);
    });

    testWidgets('an uncommitted tag draft is worth asking about', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());

      await tester.enterText(tagInput(), 'nou');
      await tester.pump();
      await pressSystemBack(tester);

      expect(find.text('Discard changes?'), findsOneWidget);
    });

    testWidgets('a draft stranded behind the tag cap does not trap the user', (
      tester,
    ) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);

      await tester.enterText(tagInput(), 'half typed');
      await tester.pump();

      // The chips are a `watch()` stream, so the cap can arrive from an import
      // or another surface while this editor is open. The input goes with it —
      // and the text stays in a controller nobody can reach.
      repository.emitTags(<TagEntity>[
        for (int i = 0; i < kMaxTagsPerCard; i++)
          repository.tag('tag-$i', name: 'tag $i'),
      ]);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add), findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Nothing visible is unsaved, so nothing is asked — and the only way out
      // is not `Discard` on changes the user cannot see.
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('deck detail'), findsOneWidget);
    });

    testWidgets('and the draft comes back when a tag is removed', (
      tester,
    ) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);

      await tester.enterText(tagInput(), 'half typed');
      await tester.pump();
      repository.emitTags(<TagEntity>[
        for (int i = 0; i < kMaxTagsPerCard; i++)
          repository.tag('tag-$i', name: 'tag $i'),
      ]);
      await tester.pumpAndSettle();

      repository.emitTags(<TagEntity>[
        for (int i = 0; i < kMaxTagsPerCard - 1; i++)
          repository.tag('tag-$i', name: 'tag $i'),
      ]);
      await tester.pumpAndSettle();

      // Suppressed, not discarded: the text was never taken away, so the guard
      // arms again the moment the user can act on it.
      expect(find.text('half typed'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
    });

    testWidgets('close is inert while a save is in flight', (tester) async {
      final repository = seed();
      final gate = Completer<void>();
      repository.updateGate = gate;
      await pumpCardEditor(tester, repository);

      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();
      await tester.tap(saveButton());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Neither exit: a pop would land the write on a screen that is gone, and
      // a discard dialog would offer to throw away work already being written.
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('deck detail'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(repository.updates, hasLength(1));
      expect(find.text('deck detail'), findsOneWidget);
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

    testWidgets('a successful save leaves without asking to discard', (
      tester,
    ) async {
      final repository = seed();
      await pumpCardEditor(tester, repository);

      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      // The guard must not swallow the screen's own exit: the whole point of
      // `canPop: false` is that something has to let this through.
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('deck detail'), findsOneWidget);
      expect(repository.updates.single.front, 'new front');
    });

    testWidgets('a failed save keeps the text, the screen and the dirty flag', (
      tester,
    ) async {
      final repository = seed();
      repository.nextCreateFailure = const DatabaseFailure(message: 'nope');
      await pumpCardEditor(tester, repository);

      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.text('deck detail'), findsNothing);
      expect(find.text('new front'), findsOneWidget);
      expect(isSaveEnabled(tester), isTrue);
      expect(find.textContaining('saved'), findsWidgets);
    });
  });

  group('the discard dialog on the smallest screen', () {
    testWidgets('the whole message is reachable, and says so', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpCardEditor(
        tester,
        seed(),
        locale: const Locale('vi'),
        textScale: 2,
      );
      await tester.enterText(find.byType(TextField).first, 'x');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // **Measured, and it was cut.** At this viewport the message needs 205
      // and is given 160, so the clause saying tags and the flag are *not*
      // lost fell outside the box — on a line boundary, with nothing to say
      // the sentence continued.
      final Finder message = find.textContaining('Thẻ nhãn và cờ');
      expect(message, findsOneWidget);

      final ScrollableState scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        scrollable.position.maxScrollExtent,
        greaterThan(0),
        reason: 'the message does not fit, so it must be scrollable',
      );

      // A thumb that is there before the user touches anything — one that
      // appears on scroll cannot tell you there is something to scroll to.
      expect(find.byType(Scrollbar), findsWidgets);

      await tester.drag(message, const Offset(0, -120));
      await tester.pumpAndSettle();

      final Rect viewport = tester.getRect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(SingleChildScrollView),
        ),
      );
      expect(
        tester.getRect(message).bottom,
        lessThanOrEqualTo(viewport.bottom),
      );
    });
  });

  group('the save action is pinned, not scrolled', () {
    testWidgets('it is not inside the scroll view', (tester) async {
      await pumpCardEditor(tester, seed());

      expect(
        find.ancestor(
          of: find.byType(CardEditorActionBarWidget),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
    });

    testWidgets('it stays on screen after scrolling to the delete action', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed(), surfaceSize: const Size(390, 700));

      final Rect before = tester.getRect(saveButton());
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delete card'), findsOneWidget);
      expect(tester.getRect(saveButton()), before);
    });

    testWidgets('it keeps its rect from pristine through dirty', (
      tester,
    ) async {
      await pumpCardEditor(tester, seed());

      final Rect pristine = tester.getRect(saveButton());

      await tester.enterText(find.byType(TextField).first, 'new front');
      await tester.pump();

      // A button that resizes when it becomes pressable moves the thing the
      // user is about to press.
      expect(tester.getRect(saveButton()), pristine);
    });
  });
}
