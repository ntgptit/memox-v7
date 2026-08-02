import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/state/submit_outcome.dart';
import 'package:memox/core/state/submit_state.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_form_sheet.dart';

/// The two behaviours a form sheet owns, neither of which a static specimen
/// can show.
///
/// Both were written inside Deck and promoted when Card's editor became the
/// second caller. The point of testing them here rather than through a feature
/// is that the guarantees are the shared ones: the keyboard cannot cover the
/// submit button, and a form that saved *and stayed open* does not close.
void main() {
  /// A problem enum stands in for a feature's own.
  ///
  /// `SubmitState` is generic over one, so the host has to be too — a host
  /// pinned to Deck's enum is a host Card cannot use, which is the shape this
  /// promotion was undoing.
  const state = SubmitState<_TestProblem>();

  Widget host({
    required SubmitState<_TestProblem> value,
    required VoidCallback onDone,
  }) => MaterialApp(
    theme: buildLightTheme(),
    home: MxFormHost<_TestProblem>(
      state: value,
      onDone: onDone,
      child: const Text('form body'),
    ),
  );

  group('the host closes on a transition, not on a value', () {
    testWidgets('a saved-and-close outcome closes exactly once', (
      tester,
    ) async {
      var closed = 0;
      const closing = SubmitState<_TestProblem>(
        outcome: SubmitOutcome.savedAndClose,
      );

      await tester.pumpWidget(host(value: state, onDone: () => closed += 1));
      expect(closed, 0, reason: 'nothing has succeeded yet');

      await tester.pumpWidget(host(value: closing, onDone: () => closed += 1));
      expect(closed, 1);

      // The same value again is a rebuild, not a new success. Reading the
      // outcome instead of the transition would pop the sheet a second time —
      // and on a Navigator that means popping the screen underneath it.
      await tester.pumpWidget(host(value: closing, onDone: () => closed += 1));
      expect(closed, 1, reason: 'a rebuild is not a second success');
    });

    testWidgets('a saved-and-continue outcome does NOT close', (tester) async {
      // The add-another flow, and the reason `shouldClose` exists instead of
      // "succeeded". Closing here would let an add-another editor accept
      // exactly one entry — the bug this distinction was written to prevent,
      // before any form existed that could hit it.
      var closed = 0;
      const continuing = SubmitState<_TestProblem>(
        outcome: SubmitOutcome.savedAndContinue,
      );

      await tester.pumpWidget(host(value: state, onDone: () => closed += 1));
      await tester.pumpWidget(
        host(value: continuing, onDone: () => closed += 1),
      );

      expect(closed, 0);
      expect(
        continuing.shouldClearDraft,
        isTrue,
        reason: 'the editor stays open and clears itself instead',
      );
    });

    testWidgets('neither a failure nor a field problem closes it', (
      tester,
    ) async {
      // Both are the same requirement seen from two sides: whatever went
      // wrong, the sheet stays up with what the user typed still in it (UC-04
      // E3). A host that closed here would discard the content along with the
      // form, and the user would have to retype it to find out what was wrong.
      var closed = 0;
      const cases = <String, SubmitState<_TestProblem>>{
        'a failed write': SubmitState<_TestProblem>(
          failure: DatabaseFailure(message: 'write failed'),
        ),
        'a field problem': SubmitState<_TestProblem>(
          problems: <_TestProblem>{_TestProblem.somethingWrong},
        ),
      };

      for (final MapEntry<String, SubmitState<_TestProblem>> entry
          in cases.entries) {
        await tester.pumpWidget(host(value: state, onDone: () => closed += 1));
        await tester.pumpWidget(
          host(value: entry.value, onDone: () => closed += 1),
        );

        expect(closed, 0, reason: '${entry.key} closed the form');
      }
    });
  });

  group('the sheet keeps the submit button above the keyboard', () {
    testWidgets('the bottom padding follows the view insets', (tester) async {
      // The failure this exists to prevent: without `isScrollControlled` and
      // the view inset, the sheet is capped at half the screen and the keyboard
      // covers the submit button — a form that cannot be submitted without
      // dismissing the keyboard first.
      const keyboard = 300.0;
      late double bottomInsetSeen;

      // Set on the platform view, not with a `MediaQuery` widget below the app.
      // The sheet is a route: its content is built under the Navigator, so it
      // reads the `MediaQuery` the app was given and never sees one wrapped
      // around the button that opened it. A test that simulated the keyboard
      // the wrong way would report a bottom inset of zero and look like a bug
      // in the sheet.
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildLightTheme(),
            home: Scaffold(
              body: Builder(
                builder: (inner) => TextButton(
                  onPressed: () => showMxFormSheet(
                    inner,
                    reset: (_) {},
                    builder: (sheetContext, ref, close) {
                      bottomInsetSeen = MediaQuery.viewInsetsOf(
                        sheetContext,
                      ).bottom;

                      return const Text('submit');
                    },
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('submit'), findsOneWidget);
      expect(
        bottomInsetSeen,
        keyboard,
        reason:
            'the sheet did not see the keyboard, so its padding cannot clear '
            'it and the submit button sits underneath',
      );

      // Any padding in the sheet that clears the keyboard will do — the claim
      // is that the content is pushed above it, not which widget does the
      // pushing. Named by value rather than by position in the ancestor chain,
      // because a `Padding` count is a detail of whatever the caller built.
      final bottoms = tester
          .widgetList<Padding>(
            find.ancestor(
              of: find.text('submit'),
              matching: find.byType(Padding),
            ),
          )
          .map((Padding p) => (p.padding as EdgeInsets).bottom);

      expect(
        bottoms,
        contains(greaterThan(keyboard)),
        reason:
            'nothing above the form body clears the keyboard, so the submit '
            'button sits underneath it. Measured: ${bottoms.toList()}',
      );
    });

    testWidgets('reset runs when the sheet opens, not when it closes', (
      tester,
    ) async {
      // Resetting from `dispose` races the controller's own disposal: an
      // autoDispose provider with no listeners left is already gone by the time
      // a scheduled callback runs, and touching its Ref throws. Clearing at
      // open is deterministic and gives the same guarantee.
      final events = <String>[];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildLightTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: Builder(
                  builder: (inner) => TextButton(
                    onPressed: () => showMxFormSheet(
                      inner,
                      reset: (_) => events.add('reset'),
                      builder: (_, _, _) => const Text('body'),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(events, <String>['reset']);
    });
  });
}

/// Stands in for a feature's problem enum.
enum _TestProblem { somethingWrong }
