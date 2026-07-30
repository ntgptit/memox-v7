import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/root_deck_summary_model.dart';
import 'package:memox/features/deck/presentation/root_deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// A submit that succeeds pops exactly one route, and the screen underneath
/// survives it.
///
/// Four places react to a submit succeeding by popping. Three use `ref.listen`,
/// which Riverpod only calls on a change; the fourth is
/// `_FormHost.didUpdateWidget`, which the framework calls on **every** parent
/// rebuild and is guarded by hand:
///
/// ```dart
/// if (widget.state.shouldClose && !oldWidget.state.shouldClose) widget.onDone();
/// ```
///
/// **What fault injection actually showed, which is not what I assumed.** Removing
/// the `!oldWidget…` half does *not* make these tests fail, and it does not appear
/// to double-pop at all — even with the keyboard churn below. The reason is that
/// the state after a success is terminal: nothing changes it again, so the
/// `Consumer` above `_FormHost` is not rebuilt again, so `didUpdateWidget` is not
/// called again. The guard is defence in depth against a future rearrangement —
/// a host that also watched something live, or a parent that rebuilt for its own
/// reasons — not a patch for a bug that is currently reachable. It is worth
/// keeping and it is worth not overstating.
///
/// So these tests pin the **behaviour**, not that line: after a successful submit
/// the sheet is gone, the screen that opened it is still mounted, and the
/// repository received exactly one write. Before them, every test in this feature
/// called `pumpAndSettle` once and asserted what the repository received — which a
/// double pop, or a sheet that failed to close, would not have changed.
void main() {
  final english = AppLocalizationsEn();

  List<RootDeckSummary> oneSummary() => <RootDeckSummary>[
    fakeSummary(id: '1', name: 'Japanese N5', totalCardCount: 120),
  ];

  /// Pumps through the close, with the keyboard dismissing part-way.
  ///
  /// The keyboard is the part that matters. A form sheet closes with the keyboard
  /// open, so `viewInsets` change on the way out, which rebuilds every widget
  /// under the `MediaQuery` — including the host that reacts to the submit state.
  /// A widget test has no keyboard and never produces that rebuild by itself, so
  /// the one condition that can fire the side effect twice has to be supplied.
  Future<void> pumpThroughClose(WidgetTester tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump(const Duration(milliseconds: 25));
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 25));
    }
    // The keyboard goes away as the sheet does.
    tester.view.viewInsets = FakeViewPadding.zero;
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 25));
    }
    await tester.pumpAndSettle();
  }

  group('a form that closes itself pops exactly one route', () {
    testWidgets('creating a root deck leaves the list screen mounted', (
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

      await pumpThroughClose(tester);

      // The sheet is gone…
      expect(find.byType(TextField), findsNothing);
      // …and the screen it opened over is not. A second pop would have taken it.
      expect(find.byType(RootDeckListScreen), findsOneWidget);
      // And the write still happened exactly once, which rules out the other
      // way this could pass: the form never submitting at all.
      expect(repository.createdRootDecks, hasLength(1));
    });

    testWidgets('renaming a deck leaves the list screen mounted', (
      tester,
    ) async {
      // The same host with a different controller, because the guard lives in
      // the shared `_FormHost` and a clone would inherit whichever one it copied.
      final repository = FakeDeckRepository.withSummaries(oneSummary());
      await pumpDeckApp(tester, repository: repository);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckRenameAction));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Renamed');
      await tester.tap(find.text(english.deckRenameSubmitAction));

      await pumpThroughClose(tester);

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(RootDeckListScreen), findsOneWidget);
      expect(repository.renames, hasLength(1));
    });
  });

  group('a confirm dialog runs its callback once', () {
    testWidgets('deleting reports the deletion a single time', (tester) async {
      // `onDeleted` is where a caller navigates away, so firing it twice would
      // mean two `goNamed` calls. The dialog guards the transition; this counts
      // the result rather than trusting it.
      final repository = FakeDeckRepository.withSummaries(oneSummary());
      await pumpDeckApp(tester, repository: repository);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckDeleteAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckDeleteConfirmAction));

      await pumpThroughClose(tester);

      expect(repository.deletes, hasLength(1));
      expect(find.byType(RootDeckListScreen), findsOneWidget);
    });
  });
}
