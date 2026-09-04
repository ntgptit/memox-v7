import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/state/submit_outcome.dart';
import 'package:memox/core/state/submit_state.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_async_confirm_dialog.dart';

/// A20.1 P1-05 — the async confirm dialog cannot be dismissed while the
/// write is in flight, so the transition that carries the Undo is never
/// unmounted before it fires.
/// A problem enum stands in for a feature's own; `SubmitState` is generic
/// over one.
enum _Problem { none }

void main() {
  testWidgets(
    'the barrier is refused mid-write and onDone fires exactly once',
    (tester) async {
      final state = ValueNotifier<SubmitState<_Problem>>(
        const SubmitState<_Problem>(),
      );
      var done = 0;
      expect(_Problem.values, hasLength(1));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildLightTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => showMxAsyncConfirm(
                      context,
                      reset: (_) {},
                      builder: (dialogContext, close) =>
                          ValueListenableBuilder<SubmitState<_Problem>>(
                            valueListenable: state,
                            builder: (_, value, _) =>
                                MxAsyncConfirmDialog<_Problem>(
                                  state: value,
                                  title: 'Delete deck?',
                                  message: 'Thirty days in Trash.',
                                  confirmLabel: 'Delete',
                                  cancelLabel: 'Cancel',
                                  onConfirm: () {},
                                  onCancel: close,
                                  onDone: () {
                                    done += 1;
                                    close();
                                  },
                                ),
                          ),
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
      expect(find.text('Delete deck?'), findsOneWidget);

      // The write starts; the barrier is tapped. Until P1-05 this popped the
      // route and the listener with it.
      // `pump`, not `pumpAndSettle`: the submitting spinner animates for as
      // long as the write is in flight, so the tree never settles here.
      state.value = const SubmitState<_Problem>(isSubmitting: true);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tapAt(const Offset(5, 5));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Delete deck?'),
        findsOneWidget,
        reason: 'dismissed mid-write',
      );
      expect(done, 0);

      // The write lands; the dialog closes through its own transition, once.
      state.value = const SubmitState<_Problem>(
        outcome: SubmitOutcome.savedAndClose,
      );
      await tester.pumpAndSettle();
      expect(done, 1);
      expect(find.text('Delete deck?'), findsNothing);

      // And at rest the barrier still dismisses.
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      state.value = const SubmitState<_Problem>();
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Delete deck?'), findsNothing);
      expect(done, 1);
    },
  );
}
