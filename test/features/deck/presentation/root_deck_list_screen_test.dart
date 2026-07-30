import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/root_deck_summary_model.dart';
import 'package:memox/features/deck/domain/scheduler_type_model.dart';
import 'package:memox/features/deck/presentation/deck_tile_widget.dart';
import 'package:memox/features/deck/presentation/root_deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The root deck list (UC-06), and the create-root flow end to end (UC-02).
///
/// The state matrix runs against the fake; the create flow runs against real
/// SQLite through the real router, because "the deck appears in the list after
/// you create it" is only worth asserting when a database actually produced the
/// list.
void main() {
  final english = AppLocalizationsEn();

  List<RootDeckSummary> threeSummaries() => <RootDeckSummary>[
    fakeSummary(
      id: '1',
      name: 'Japanese N5',
      totalCardCount: 120,
      dueCardCount: 7,
    ),
    fakeSummary(id: '2', name: 'Spanish verbs', totalCardCount: 40),
    fakeSummary(
      id: '3',
      name: 'Kanji radicals',
      schedulerType: SchedulerType.sm2,
    ),
  ];

  group('loading', () {
    testWidgets('shows the shared loading state, announced to a reader', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.pending(),
        screen: const RootDeckListScreen(),
      );

      expect(
        tester
            .widget<MxLoadingState>(find.byType(MxLoadingState))
            .semanticsLabel,
        english.decksLoadingLabel,
      );
      // The title stays put while the body swaps, so the screen does not appear
      // to be replaced every time the data changes.
      expect(find.text(english.decksTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('empty', () {
    testWidgets('reads as a starting point and offers the create action', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository(),
        screen: const RootDeckListScreen(),
      );

      final empty = tester.widget<MxEmptyState>(find.byType(MxEmptyState));
      expect(find.text(english.decksEmptyTitle), findsOneWidget);
      expect(find.text(english.decksEmptyMessage), findsOneWidget);
      // Unlike M4.10 slice 1, the action now leads somewhere real.
      expect(empty.actionLabel, english.deckCreateRootAction);
      expect(empty.onAction, isNotNull);
      expect(find.byType(MxErrorState), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('loaded', () {
    testWidgets('each row shows name, totals, due state and study mode', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const RootDeckListScreen(),
      );

      expect(find.byType(DeckTileWidget), findsNWidgets(3));
      expect(find.text('Japanese N5'), findsOneWidget);
      // Totals, due count and mode, on one subtitle line.
      expect(
        find.textContaining(english.deckCardCountLabel(120)),
        findsOneWidget,
      );
      expect(find.textContaining(english.deckDueCountLabel(7)), findsOneWidget);
      expect(find.textContaining(english.schedulerEightBoxLabel), findsWidgets);
      expect(find.textContaining(english.schedulerSm2Label), findsOneWidget);
    });

    testWidgets('a deck with nothing due says so, neutrally (BR-29)', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const RootDeckListScreen(),
      );

      expect(find.textContaining(english.deckNoDueLabel), findsNWidgets(2));
    });

    testWidgets('due state is carried by an icon as well as words', (
      tester,
    ) async {
      // UC-06 step 3. Colour alone fails for a colour-blind user and in
      // high-contrast modes, so the icon and the text both have to say it.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const RootDeckListScreen(),
      );

      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(english.deckDueSemanticLabel)),
        findsWidgets,
      );
    });

    testWidgets('a later emission updates the list without a manual refresh', (
      tester,
    ) async {
      // UC-06 A2, the reason the read is a stream.
      final controller = StreamController<List<RootDeckSummary>>();
      addTearDown(controller.close);

      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository(summaries: () => controller.stream),
        screen: const RootDeckListScreen(),
      );

      controller.add(const <RootDeckSummary>[]);
      await tester.pump();
      expect(find.byType(MxEmptyState), findsOneWidget);

      controller.add(threeSummaries());
      await tester.pump();

      expect(find.byType(DeckTileWidget), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });

  group('error', () {
    testWidgets('shows localized copy and no technical detail', (tester) async {
      const failure = DatabaseFailure(
        message: 'SqliteException(11): database disk image is malformed',
      );
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.failing(failure),
        screen: const RootDeckListScreen(),
      );

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.text(english.decksLoadErrorTitle), findsOneWidget);
      // The Failure's own message is a developer string and must never be what
      // the user reads, even though it is right there on the exception.
      expect(find.textContaining('Sqlite'), findsNothing);
      expect(find.textContaining('malformed'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('retry re-subscribes and can recover into a loaded list', (
      tester,
    ) async {
      var attempt = 0;
      final repository = FakeDeckRepository(
        summaries: () {
          attempt += 1;
          if (attempt == 1) {
            return Stream<List<RootDeckSummary>>.error(
              const DatabaseFailure(message: 'read failed'),
            );
          }

          return Stream<List<RootDeckSummary>>.value(threeSummaries());
        },
      );

      await pumpDeckScreen(
        tester,
        repository: repository,
        screen: const RootDeckListScreen(),
      );
      expect(find.byType(MxErrorState), findsOneWidget);

      await tester.tap(find.text(english.retryAction));
      await tester.pumpAndSettle();

      expect(repository.summariesCallCount, 2);
      expect(find.byType(DeckTileWidget), findsNWidgets(3));
    });
  });

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

  group('responsive and accessibility', () {
    const compact = Size(320, 568);

    testWidgets('the loaded list fits 320x568', (tester) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const RootDeckListScreen(),
        surface: compact,
      );

      expect(find.byType(DeckTileWidget), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the loaded list survives textScaler 2.0 on 320x568', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const RootDeckListScreen(),
        surface: compact,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('the empty state survives textScaler 2.0 on 320x568', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository(),
        screen: const RootDeckListScreen(),
        surface: compact,
        textScale: 2,
      );

      expect(find.byType(MxEmptyState), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a very long deck name does not break the row', (tester) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(<RootDeckSummary>[
          fakeSummary(id: '1', name: 'A' * 200, totalCardCount: 1),
        ]),
        screen: const RootDeckListScreen(),
        surface: compact,
        textScale: 2,
      );

      expect(find.byType(DeckTileWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('every state builds under the dark theme', (tester) async {
      for (final repository in <FakeDeckRepository>[
        FakeDeckRepository.pending(),
        FakeDeckRepository(),
        FakeDeckRepository.withSummaries(threeSummaries()),
        FakeDeckRepository.failing(const DatabaseFailure(message: 'x')),
      ]) {
        await pumpDeckScreen(
          tester,
          repository: repository,
          screen: const RootDeckListScreen(),
          isDark: true,
        );

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the row action button carries a semantics label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const RootDeckListScreen(),
      );

      expect(
        find.bySemanticsLabel(RegExp(english.deckActionsSemanticLabel)),
        findsWidgets,
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

      handle.dispose();
    });
  });
}
