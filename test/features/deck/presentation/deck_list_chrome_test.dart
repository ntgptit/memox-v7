import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The deck level's chrome across its three read states.
///
/// The shell is built inside each async branch here — the title is only knowable
/// in some of them — which is legitimate and is also how the branches drifted
/// apart: for a while only the loaded one passed `actions` and a subline, so the
/// bar changed height and lost every control the moment a read was slow or
/// failed. `deck_list_screen_test.dart` asserts which body each state renders;
/// this file asserts that the frame around them stays the same frame.
void main() {
  final english = AppLocalizationsEn();

  List<DeckSummary> threeSummaries() => <DeckSummary>[
    fakeSummary(id: '1', name: 'Japanese N5', totalCardCount: 120),
    fakeSummary(id: '2', name: 'Spanish verbs', totalCardCount: 40),
    fakeSummary(id: '3', name: 'Kanji radicals'),
  ];

  double barHeight(WidgetTester tester) =>
      tester.getRect(find.byType(AppBar)).height;

  group('the root bar keeps its height across the read', () {
    for (final textScale in <double>[1, 2]) {
      testWidgets('loading and loaded measure the same at textScaler '
          '$textScale', (tester) async {
        // One controller, one screen: the same widget is measured before and
        // after the snapshot lands, so a difference is the branch changing the
        // bar rather than two set-ups disagreeing.
        final controller = StreamController<DeckListSnapshot>();
        addTearDown(controller.close);

        await pumpDeckScreen(
          tester,
          repository: FakeDeckRepository(deckList: (_) => controller.stream),
          screen: const DeckListScreen(),
          textScale: textScale,
        );

        final whileLoading = barHeight(tester);

        controller.add(fakeListSnapshot(threeSummaries()));
        await tester.pump();

        // The measured step used to be 28.0dp at scale 1.0 and 37.5 at 2.0 —
        // `MxContentShell` sizes the row to the block it holds and only the
        // loaded branch passed a subline, so every body pixel moved down when
        // the data arrived.
        expect(whileLoading, closeTo(barHeight(tester), 0.5));
      });
    }

    testWidgets('the reserved line is an empty one, not a second title', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.pending(),
        screen: const DeckListScreen(),
      );

      final shell = tester.widget<MxContentShell>(find.byType(MxContentShell));
      expect(shell.titleSubline, isNotNull);
      expect(find.text(english.deckPathRootLabel), findsNothing);
    });

    testWidgets('inside a deck the slot is left alone, on purpose', (
      tester,
    ) async {
      // The exception the fix is scoped around: a subline tells the shell the
      // title owns the way back, so reserving the slot on a level whose
      // breadcrumb has not arrived would buy an even bar and pay for it with a
      // titleless, back-less one. Inside a deck the bar steps once, when the
      // name and the path arrive together.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.pending(),
        screen: const DeckListScreen(parentDeckId: 'deck-1'),
      );

      final shell = tester.widget<MxContentShell>(find.byType(MxContentShell));
      expect(shell.titleSubline, isNull);
    });
  });

  group('the root bar keeps its actions across the read', () {
    Future<void> expectBothActions(WidgetTester tester) async {
      // By tooltip rather than by icon: `Icons.more_vert` is also every deck
      // row's own action button, so an icon finder cannot say which control it
      // found in the loaded state.
      expect(find.byTooltip(english.librarySearchOpenLabel), findsOneWidget);
      expect(find.byTooltip(english.libraryActionsTitle), findsOneWidget);
    }

    testWidgets('while the read is still running', (tester) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.pending(),
        screen: const DeckListScreen(),
      );

      await expectBothActions(tester);
    });

    testWidgets('and after it fails', (tester) async {
      // The one that mattered: this overflow is the only door to Trash (AD-22
      // keeps the entry root-only) and to the tag catalogue, and a failed read
      // used to close both.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.failing(
          const DatabaseFailure(message: 'read failed'),
        ),
        screen: const DeckListScreen(),
      );

      await expectBothActions(tester);
    });

    testWidgets('and once it lands', (tester) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const DeckListScreen(),
      );

      await expectBothActions(tester);
    });

    testWidgets('the search entry still works from the failed state', (
      tester,
    ) async {
      // Present is not the same as live: the action is built outside the branch
      // now, so it has to still be a button rather than a decoration.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.failing(
          const DatabaseFailure(message: 'read failed'),
        ),
        screen: const DeckListScreen(),
      );

      final button = tester.widget<MxIconButton>(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is MxIconButton &&
              widget.semanticLabel == english.librarySearchOpenLabel,
        ),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
