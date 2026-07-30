import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// Creating a root deck from the list (UC-02), and the shell that stays put
/// while the form is open.
///
/// Split from `root_deck_list_screen_test.dart`, which keeps the four read
/// states and the responsive matrix.
void main() {
  final english = AppLocalizationsEn();

  group('create a root deck (UC-02)', () {
    // These assert the **form**: what it sends, what it refuses, and that it
    // closes itself. What the write then does to the tree is asserted against
    // real SQLite in `test/features/deck/data/`, and the aggregate re-emitting
    // after a create is asserted there too.
    //
    // Deliberately split rather than combined. A widget test driving a real
    // Drift database leaves the stream-notification timer pending when the tree
    // is torn down, and `flutter_test` fails the test for it — so an
    // "end-to-end" widget test here would be a test about teardown timing, not
    // about UC-02.
    testWidgets('sends the typed name and the chosen mode, then closes', (
      tester,
    ) async {
      final repository = FakeDeckRepository();
      await pumpDeckApp(tester, repository: repository);

      await tester.tap(find.text(english.deckCreateRootAction));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Japanese N5');
      await tester.tap(find.text(english.schedulerSm2Label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckFormSubmitAction));
      await tester.pumpAndSettle();

      expect(repository.createdRootDecks.single.name, 'Japanese N5');
      expect(repository.createdRootDecks.single.scheduler, SchedulerType.sm2);
      // The sheet closed itself on success rather than needing a second tap.
      expect(find.text(english.deckFormSubmitAction), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('submitting without a study mode blocks and explains', (
      tester,
    ) async {
      // BR-11 has no implicit default, so the form must refuse rather than pick.
      final repository = FakeDeckRepository();
      await pumpDeckApp(tester, repository: repository);

      await tester.tap(find.text(english.deckCreateRootAction));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Japanese N5');
      await tester.tap(find.text(english.deckFormSubmitAction));
      await tester.pumpAndSettle();

      expect(find.text(english.schedulerMissingError), findsOneWidget);
      // Still open, and nothing was written.
      expect(find.text(english.deckFormSubmitAction), findsOneWidget);
      expect(repository.createdRootDecks, isEmpty);
    });

    testWidgets('an empty name blocks with an inline error', (tester) async {
      final repository = FakeDeckRepository();
      await pumpDeckApp(tester, repository: repository);

      await tester.tap(find.text(english.deckCreateRootAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.schedulerEightBoxLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckFormSubmitAction));
      await tester.pumpAndSettle();

      expect(find.text(english.deckNameEmptyError), findsOneWidget);
      expect(repository.createdRootDecks, isEmpty);
    });

    testWidgets('a persistence failure keeps the form and its input', (
      tester,
    ) async {
      // UC-02 E4. The typed text lives in the widget, so a failed write cannot
      // destroy it — this is what proves the form does not clear on error.
      final repository = FakeDeckRepository(
        writeFailure: const DatabaseFailure(message: 'disk full'),
      );
      await pumpDeckApp(tester, repository: repository);

      await tester.tap(find.text(english.deckCreateRootAction));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Japanese N5');
      await tester.tap(find.text(english.schedulerSm2Label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckFormSubmitAction));
      await tester.pumpAndSettle();

      expect(find.text(english.deckWriteErrorMessage), findsOneWidget);
      expect(find.text('Japanese N5'), findsOneWidget);
      expect(find.text(english.deckFormSubmitAction), findsOneWidget);
    });

    testWidgets('the study-mode notice explains that the choice locks', (
      tester,
    ) async {
      // UC-02 step 3 requires it: the choice is hard to undo and the form has to
      // say so before it is made.
      await pumpDeckApp(tester, repository: FakeDeckRepository());

      await tester.tap(find.text(english.deckCreateRootAction));
      await tester.pumpAndSettle();

      expect(find.text(english.schedulerLockNotice), findsOneWidget);
      expect(find.text(english.schedulerEightBoxDescription), findsOneWidget);
      expect(find.text(english.schedulerSm2Description), findsOneWidget);
    });

    testWidgets('cancelling a form with typed input asks first (UC-02 A1)', (
      tester,
    ) async {
      await pumpDeckApp(tester, repository: FakeDeckRepository());

      await tester.tap(find.text(english.deckCreateRootAction));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Half typed');
      await tester.tap(find.text(english.commonCancelAction).first);
      await tester.pumpAndSettle();

      expect(find.text(english.deckFormDiscardTitle), findsOneWidget);
    });

    testWidgets('cancelling an untouched form closes without asking', (
      tester,
    ) async {
      await pumpDeckApp(tester, repository: FakeDeckRepository());

      await tester.tap(find.text(english.deckCreateRootAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.commonCancelAction));
      await tester.pumpAndSettle();

      expect(find.text(english.deckFormDiscardTitle), findsNothing);
      expect(find.text(english.deckFormSubmitAction), findsNothing);
    });
  });

  group('the shell stays put', () {
    testWidgets('the bottom bar is present on the list', (tester) async {
      await pumpDeckApp(tester, repository: FakeDeckRepository());

      expect(find.byType(MxNavigationBar), findsOneWidget);
    });
  });
}
