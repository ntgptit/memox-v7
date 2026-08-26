import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/state/submit_outcome.dart';
import 'package:memox/core/state/submit_state.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_async_confirm_dialog.dart';

/// The transition four dialogs used to each own a copy of.
///
/// **One of those copies was wrong when it shipped**, and the bug is the first
/// case below: settings reset closed only on success, `submitStateFromFailure`
/// produces a state carrying a `failure` and no `outcome`, and so a failed
/// reset left the dialog standing over the error band it was hiding. That is
/// why the policy is an enum with two members rather than a condition each
/// caller writes — and why both members are pinned here.
enum _Problem { nameEmpty }

typedef _State = SubmitState<_Problem>;

void main() {
  /// Drives the dialog through a sequence of states, counting closes.
  ///
  /// A plain `StatefulWidget` and not a `ProviderContainer`: the widget takes a
  /// value, so the test can hand it the exact state sequence a controller would
  /// produce — including the ones that are hard to reach through a real write.
  Future<_Closes> pump(
    WidgetTester tester, {
    required MxConfirmCloseWhen closeWhen,
    bool isBlocked = false,
  }) async {
    final closes = _Closes();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: _Harness(
            closeWhen: closeWhen,
            isBlocked: isBlocked,
            onDone: closes.record,
          ),
        ),
      ),
    );

    return closes;
  }

  group('closeWhen: saved', () {
    testWidgets('a failure does not close it — the reason is read in place', (
      tester,
    ) async {
      final closes = await pump(tester, closeWhen: MxConfirmCloseWhen.saved);

      _HarnessState.of(
        tester,
      ).push(const _State(failure: DatabaseFailure(message: 'write refused')));
      await tester.pump();

      expect(closes.count, 0);
    });

    testWidgets('savedAndClose closes it', (tester) async {
      final closes = await pump(tester, closeWhen: MxConfirmCloseWhen.saved);

      _HarnessState.of(
        tester,
      ).push(const _State(outcome: SubmitOutcome.savedAndClose));
      await tester.pump();

      expect(closes.count, 1);
    });

    testWidgets('savedAndContinue does not — an *add another* form keeps it', (
      tester,
    ) async {
      final closes = await pump(tester, closeWhen: MxConfirmCloseWhen.saved);

      _HarnessState.of(
        tester,
      ).push(const _State(outcome: SubmitOutcome.savedAndContinue));
      await tester.pump();

      expect(closes.count, 0);
    });
  });

  group('closeWhen: settled', () {
    testWidgets('a failure closes it — the band behind is where W4 puts it', (
      tester,
    ) async {
      final closes = await pump(tester, closeWhen: MxConfirmCloseWhen.settled);

      _HarnessState.of(
        tester,
      ).push(const _State(failure: DatabaseFailure(message: 'write refused')));
      await tester.pump();

      expect(
        closes.count,
        1,
        reason:
            'this is the settings-reset bug: a state with a failure and no '
            'outcome must count as settled',
      );
    });

    testWidgets('savedAndContinue closes it too', (tester) async {
      final closes = await pump(tester, closeWhen: MxConfirmCloseWhen.settled);

      _HarnessState.of(
        tester,
      ).push(const _State(outcome: SubmitOutcome.savedAndContinue));
      await tester.pump();

      expect(
        closes.count,
        1,
        reason:
            'settings reset reports savedAndContinue so canSubmit stays true '
            'for a later reset — the dialog still has to go',
      );
    });
  });

  group('it fires on the crossing, not on the value', () {
    testWidgets('rebuilding on an already-settled state does not close twice', (
      tester,
    ) async {
      final closes = await pump(tester, closeWhen: MxConfirmCloseWhen.saved);
      const settled = _State(outcome: SubmitOutcome.savedAndClose);

      _HarnessState.of(tester).push(settled);
      await tester.pump();
      _HarnessState.of(tester).push(settled);
      await tester.pump();
      _HarnessState.of(tester).push(settled);
      await tester.pump();

      expect(
        closes.count,
        1,
        reason: 'popping a route more than once tears down the screen behind',
      );
    });

    testWidgets('a field problem is not an outcome and closes nothing', (
      tester,
    ) async {
      final closes = await pump(tester, closeWhen: MxConfirmCloseWhen.settled);

      _HarnessState.of(
        tester,
      ).push(const _State(problems: <_Problem>{_Problem.nameEmpty}));
      await tester.pump();

      expect(
        closes.count,
        0,
        reason:
            'even `settled` means the write stopped — a rejected field is the '
            'form still waiting, and closing on it would throw the input away',
      );
    });

    testWidgets('an idle rebuild closes nothing', (tester) async {
      final closes = await pump(tester, closeWhen: MxConfirmCloseWhen.settled);

      _HarnessState.of(tester).push(const _State(isSubmitting: true));
      await tester.pump();

      expect(closes.count, 0);
    });
  });

  group('both actions go inert while the write runs', () {
    testWidgets('isSubmitting disables confirm and cancel', (tester) async {
      await pump(tester, closeWhen: MxConfirmCloseWhen.saved);

      _HarnessState.of(tester).push(const _State(isSubmitting: true));
      await tester.pump();

      for (final label in <String>['Delete', 'Cancel']) {
        final button = tester.widget<ButtonStyleButton>(
          find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          ),
        );
        expect(
          button.onPressed,
          isNull,
          reason:
              '$label stays live: confirming twice sends a second delete that '
              'fails against data the first already removed',
        );
      }
    });

    testWidgets('isBlocked disables confirm before the impact read lands', (
      tester,
    ) async {
      await pump(tester, closeWhen: MxConfirmCloseWhen.saved, isBlocked: true);

      final confirm = tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Delete'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );

      expect(
        confirm.onPressed,
        isNull,
        reason:
            'BR-04: never ask *are you sure* while the sentence saying what '
            'will be lost is still loading',
      );
    });

    testWidgets('isBlocked leaves Cancel live — the way out is always safe', (
      tester,
    ) async {
      await pump(tester, closeWhen: MxConfirmCloseWhen.saved, isBlocked: true);

      final cancel = tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Cancel'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );

      expect(
        cancel.onPressed,
        isNotNull,
        reason:
            'blocked is not submitting: a user who opened this by accident '
            'must not be held in it until a database read returns. The two '
            'went through one flag until a review noticed that the code and '
            'the WBS entry disagreed about it',
      );
    });
  });
}

/// How many times the dialog asked to be taken off screen.
///
/// An object the test holds rather than a counter on the harness: a second
/// close is the failure this file exists to catch, so the count has to survive
/// independently of the widget that produces it.
class _Closes {
  int count = 0;

  void record() => count++;
}

class _Harness extends StatefulWidget {
  const _Harness({
    required this.closeWhen,
    required this.isBlocked,
    required this.onDone,
  });

  final MxConfirmCloseWhen closeWhen;
  final bool isBlocked;
  final VoidCallback onDone;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  static _HarnessState of(WidgetTester tester) =>
      tester.state<_HarnessState>(find.byType(_Harness));

  _State _state = const _State();

  void push(_State next) => setState(() => _state = next);

  @override
  Widget build(BuildContext context) => MxAsyncConfirmDialog<_Problem>(
    state: _state,
    title: 'Delete this deck?',
    message: 'This deck and 12 cards go to Trash.',
    confirmLabel: 'Delete',
    cancelLabel: 'Cancel',
    closeWhen: widget.closeWhen,
    isBlocked: widget.isBlocked,
    onConfirm: () {},
    onCancel: () {},
    onDone: widget.onDone,
  );
}
