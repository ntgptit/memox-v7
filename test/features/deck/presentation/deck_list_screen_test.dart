import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/presentation/widgets/deck_tile_widget.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The root deck list's four read states and its responsive matrix (UC-06).
///
/// The create flow lives in `root_deck_create_test.dart`, and the filter and
/// sort pills in `deck_list_toolbar_test.dart`.
void main() {
  final english = AppLocalizationsEn();

  List<DeckSummary> threeSummaries() => <DeckSummary>[
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
        screen: const DeckListScreen(),
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
        screen: const DeckListScreen(),
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
        screen: const DeckListScreen(),
      );

      expect(find.byType(DeckTileWidget), findsNWidgets(3));
      expect(find.text('Japanese N5'), findsOneWidget);
      // **Totals and mode on the subtitle line; the due count is no longer on
      // it.** M4.10s moved it to a chip in the card's foot, so asserting it here
      // would be asserting the old layout.
      expect(
        find.textContaining(english.deckCardCountLabel(120)),
        findsOneWidget,
      );
      expect(find.textContaining(english.deckDueNowLabel(7)), findsOneWidget);
      expect(
        find.textContaining(english.schedulerEightBoxShortLabel),
        findsWidgets,
      );
      expect(find.textContaining(english.schedulerSm2Label), findsOneWidget);
    });

    testWidgets('a deck with nothing due says so, neutrally (BR-29)', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const DeckListScreen(),
      );

      // **Two states, not one.** One fixture has cards and none of them due;
      // the other has no cards at all. Both used to read "Nothing due", which
      // told a user who had just created a deck that they were up to date with
      // it. M4.10s split them, and asserting both is what keeps them split.
      expect(find.textContaining(english.deckNoDueLabel), findsOneWidget);
      expect(find.textContaining(english.deckNoCardsLabel), findsOneWidget);
    });

    testWidgets('due state is carried by an icon as well as words', (
      tester,
    ) async {
      // UC-06 step 3. Colour alone fails for a colour-blind user and in
      // high-contrast modes, so the icon and the text both have to say it.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const DeckListScreen(),
      );

      // `schedule` on a filled chip, not `notifications_active` on the well.
      // The well now says what the deck is made of; what is waiting says so in
      // the foot, where it can be a pill rather than a tint on a glyph.
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      // **The words are the chip's own text now, not a semantic label on a
      // glyph.** The glyph used to be the only carrier, so it needed a label
      // nobody could see; the chip says "7 due now" in words a sighted user
      // reads and a screen reader announces from the same string.
      expect(find.textContaining(english.deckDueNowLabel(7)), findsOneWidget);
    });

    testWidgets('a later emission updates the list without a manual refresh', (
      tester,
    ) async {
      // UC-06 A2, the reason the read is a stream.
      final controller = StreamController<DeckListSnapshot>();
      addTearDown(controller.close);

      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository(deckList: (_) => controller.stream),
        screen: const DeckListScreen(),
      );

      controller.add(fakeListSnapshot(const <DeckSummary>[]));
      await tester.pump();
      expect(find.byType(MxEmptyState), findsOneWidget);

      controller.add(fakeListSnapshot(threeSummaries()));
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
        screen: const DeckListScreen(),
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
        deckList: (_) {
          attempt += 1;
          if (attempt == 1) {
            return Stream<DeckListSnapshot>.error(
              const DatabaseFailure(message: 'read failed'),
            );
          }

          return Stream<DeckListSnapshot>.value(
            fakeListSnapshot(threeSummaries()),
          );
        },
      );

      await pumpDeckScreen(
        tester,
        repository: repository,
        screen: const DeckListScreen(),
      );
      expect(find.byType(MxErrorState), findsOneWidget);

      await tester.tap(find.text(english.retryAction));
      await tester.pumpAndSettle();

      expect(repository.deckListCallCount, 2);
      expect(find.byType(DeckTileWidget), findsNWidgets(3));
    });
  });

  group('responsive and accessibility', () {
    const compact = Size(320, 568);

    testWidgets('the loaded list fits 320x568', (tester) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const DeckListScreen(),
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
        screen: const DeckListScreen(),
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
        screen: const DeckListScreen(),
        surface: compact,
        textScale: 2,
      );

      expect(find.byType(MxEmptyState), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a very long deck name does not break the row', (tester) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(<DeckSummary>[
          fakeSummary(id: '1', name: 'A' * 200, totalCardCount: 1),
        ]),
        screen: const DeckListScreen(),
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
          screen: const DeckListScreen(),
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
        screen: const DeckListScreen(),
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
