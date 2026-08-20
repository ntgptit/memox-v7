import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The root deck list's four read states and its responsive matrix (UC-06).
///
/// The create flow lives in `root_deck_create_test.dart`, the filter and sort
/// pills in `deck_list_toolbar_test.dart`, and the summary panel's visibility in
/// `deck_list_summary_test.dart`.
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
      // **Two ways forward, and ready-made content leads** (UC-01). Production
      // seeds nothing, so this is a real first-run screen: the starter catalog
      // is the primary action and the blank deck stays one tap away as the
      // quieter second path.
      expect(empty.actionLabel, english.deckStarterLibraryAction);
      expect(empty.onAction, isNotNull);
      expect(empty.secondaryActionLabel, english.deckCreateRootAction);
      expect(empty.onSecondaryAction, isNotNull);
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
      // Scoped to a tile: the summary metric says the same words above the
      // list, and both saying "7 Due" is the design working, not a duplicate.
      expect(
        find.descendant(
          of: find.byType(DeckTileWidget),
          matching: find.textContaining(english.deckTileDueChipLabel(7)),
        ),
        findsOneWidget,
      );
      // The scheduler is off the tile (owner mockup, 2026-08-20): the
      // algorithm is a configuration detail that lives on the deck's own
      // level now, not a column dressing every card.
      expect(
        find.textContaining(english.schedulerEightBoxShortLabel),
        findsNothing,
      );
      expect(find.textContaining(english.schedulerSm2Label), findsNothing);
    });

    testWidgets('a deck with nothing due says so, neutrally (BR-29)', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const DeckListScreen(),
      );

      // **Two states, not one.** One fixture has cards and none of them
      // pending — with nothing speaking, its workload line states both
      // zeroes outright, `0 due · 0 new`, because there an absent metric
      // would be ambiguous (BR-150). The other has no cards at all and says
      // so instead. Asserting both is what keeps them split.
      expect(
        find.textContaining(english.deckTileDueChipLabel(0)),
        findsOneWidget,
      );
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

      // The filled due-today calendar on the status well (BR-161/BR-162) —
      // the assertion is that an icon exists beside the words, not a count
      // of surfaces that speak the same language.
      expect(find.byIcon(Icons.event), findsWidgets);
      // **The words are the chip's own text now, not a semantic label on a
      // glyph.** The glyph used to be the only carrier, so it needed a label
      // nobody could see; the chip says "7 due now" in words a sighted user
      // reads and a screen reader announces from the same string.
      // Scoped to a tile: the summary metric says the same words above the
      // list, and both saying "7 Due" is the design working, not a duplicate.
      expect(
        find.descendant(
          of: find.byType(DeckTileWidget),
          matching: find.textContaining(english.deckTileDueChipLabel(7)),
        ),
        findsOneWidget,
      );
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
    const compact = Size(360, 640);

    testWidgets('the loaded list fits 320x568', (tester) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const DeckListScreen(),
        surface: compact,
      );

      // **One of three, and that is the list working.** The summary panel takes
      // the top of a 568-tall screen and the search field takes another band, so
      // the rest is below the fold — built lazily, reachable by scrolling.
      // Asserting a particular number here would be asserting that nothing above
      // the list is allowed to have height, which is a rule nobody chose. What
      // matters at this size is that nothing overflows and the rest is
      // reachable, and both are asserted below.
      expect(find.byType(DeckTileWidget), findsWidgets);
      expect(tester.takeException(), isNull);

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();

      expect(
        find.byType(DeckTileWidget),
        findsWidgets,
        reason: 'the rest of the list is reachable',
      );
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
