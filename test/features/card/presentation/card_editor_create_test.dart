import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

import 'support/card_editor_harness.dart';
import 'support/fake_card_repository.dart';

/// The editor in **create** mode (UC-04 W4, A4).
///
/// **It had no widget test at all, and that is how a regression got in.** When
/// the two sides moved into `CardSidesFieldsWidget` for edit mode's sake, the
/// front's `titleLarge` came with them and resized a create form nobody was
/// looking at — 279 goldens and 4000 tests all green, because not one of them
/// rendered this screen. These pin the parts of create that edit mode is now in
/// a position to break.
void main() {
  Finder frontField() => find.byType(TextField).first;

  FakeCardRepository seed() {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);

    return repository;
  }

  testWidgets('the front field keeps the theme input style', (tester) async {
    await pumpCardCreator(tester, seed());

    // Null, not "some other style": D27 gave the front its own weight in *edit*
    // mode, and create (W4) is not in that decision's scope. When someone
    // decides create should match, this is the line that says it was a decision.
    expect(tester.widget<TextField>(frontField()).style, isNull);
  });

  testWidgets('the details disclosure starts collapsed', (tester) async {
    await pumpCardCreator(tester, seed());

    expect(find.text(kDetailsToggleLabel), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Example'), findsNothing);
  });

  testWidgets('there is no tag strip and no delete', (tester) async {
    await pumpCardCreator(tester, seed());

    // A tag links to a card id, and an unsaved card has none.
    expect(find.text('Tags'), findsNothing);
    expect(find.text('Delete card'), findsNothing);
  });

  testWidgets('save writes the card and leaves', (tester) async {
    final repository = seed();
    await pumpCardCreator(tester, repository);

    await tester.enterText(frontField(), 'front');
    await tester.enterText(find.byType(TextField).at(1), 'back');
    await tester.tap(find.widgetWithText(MxActionButton, 'Save card'));
    await tester.pumpAndSettle();

    expect(repository.creates.single.front, 'front');
    expect(find.text('deck detail'), findsOneWidget);
  });

  testWidgets('save and add another clears the form and stays', (tester) async {
    final repository = seed();
    await pumpCardCreator(tester, repository);

    await tester.enterText(frontField(), 'front');
    await tester.enterText(find.byType(TextField).at(1), 'back');
    await tester.tap(
      find.widgetWithText(MxActionButton, 'Save and add another'),
    );
    await tester.pumpAndSettle();

    expect(repository.creates, hasLength(1));
    expect(find.text('deck detail'), findsNothing);
    expect(tester.widget<TextField>(frontField()).controller?.text, isEmpty);
    expect(tester.widget<TextField>(frontField()).focusNode?.hasFocus, isTrue);
  });

  testWidgets('a failed save keeps the text on screen', (tester) async {
    final repository = seed();
    repository.nextCreateFailure = const DatabaseFailure(message: 'nope');
    await pumpCardCreator(tester, repository);

    await tester.enterText(frontField(), 'front');
    await tester.enterText(find.byType(TextField).at(1), 'back');
    await tester.tap(find.widgetWithText(MxActionButton, 'Save card'));
    await tester.pumpAndSettle();

    expect(find.text('deck detail'), findsNothing);
    expect(find.text('front'), findsOneWidget);
  });

  testWidgets('close pops without asking anything', (tester) async {
    await pumpCardCreator(tester, seed());

    await tester.enterText(frontField(), 'typed but never saved');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Create has no discard guard, and that is the behaviour it had before this
    // change. Pinned so that adding one later is a decision rather than a leak
    // from the edit-mode work.
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('deck detail'), findsOneWidget);
  });

  testWidgets('a second tap while submitting does not write twice', (
    tester,
  ) async {
    final repository = seed();
    final gate = Completer<void>();
    repository.createGate = gate;
    await pumpCardCreator(tester, repository);

    await tester.enterText(frontField(), 'front');
    await tester.enterText(find.byType(TextField).at(1), 'back');
    final Finder save = find.widgetWithText(MxActionButton, 'Save card');
    await tester.tap(save);
    await tester.pump();
    await tester.tap(save, warnIfMissed: false);
    await tester.pump();

    expect(repository.creates, hasLength(1));

    gate.complete();
    await tester.pumpAndSettle();
  });
}
