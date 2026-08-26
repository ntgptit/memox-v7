import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';

/// The contract every caller of the confirm dialog relies on, asserted once.
///
/// **This file exists because a claim about its callers went unchecked.** The
/// live region was added with a comment saying both callers that can fail
/// *append* their reason to the body — and one of them replaces it instead
/// (D26). Nothing was red, because the only test of the behaviour lived in one
/// caller's own suite and asserted that caller's shape.
///
/// So the assertion here is deliberately caller-agnostic: whatever a caller
/// puts in `message`, and however it changes it, the body is a live region and
/// the title is not. That is the part the shared widget owes; what each caller
/// *says* is its own business and is recorded in D26.
void main() {
  group('showMxConfirm', _entryPointTests);

  Future<void> pumpDialog(WidgetTester tester, String message) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: MxConfirmDialog(
            title: 'Delete this?',
            message: message,
            confirmLabel: 'Delete',
            cancelLabel: 'Cancel',
            onConfirm: () {},
            onCancel: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder bodyText() => find
      .descendant(of: find.byType(AlertDialog), matching: find.byType(Text))
      .at(1);

  testWidgets('the body is a live region, whatever the caller puts in it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpDialog(tester, 'This deck and 12 cards will be deleted.');

    expect(tester.getSemantics(bodyText()), isSemantics(isLiveRegion: true));
    handle.dispose();
  });

  testWidgets('the title is not — it never changes, so announcing it would '
      'repeat', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpDialog(tester, 'This deck and 12 cards will be deleted.');

    final title = tester.getSemantics(
      find
          .descendant(of: find.byType(AlertDialog), matching: find.byType(Text))
          .first,
    );

    expect(title, isNot(isSemantics(isLiveRegion: true)));
    handle.dispose();
  });

  testWidgets('a replaced body and an appended body are both announced', (
    tester,
  ) async {
    // The two shapes D26 records — deck replaces the question with the reason,
    // tag appends the reason to it. The widget owes the announcement for both;
    // the difference in wording is theirs.
    final handle = tester.ensureSemantics();

    await pumpDialog(tester, 'Could not delete. Please try again.');
    expect(tester.getSemantics(bodyText()), isSemantics(isLiveRegion: true));

    await pumpDialog(
      tester,
      'Delete this tag?\n\nCould not delete. Please try again.',
    );
    expect(tester.getSemantics(bodyText()), isSemantics(isLiveRegion: true));
    handle.dispose();
  });
}

/// `showMxConfirm`'s one promise: **only the confirm button is a yes.**
///
/// Five call sites each wrote this `showDialog` themselves and each ended with
/// `?? false`, which is the promise spelled out five times — and the fifth had
/// already drifted into a bare `AlertDialog` with neither the destructive
/// colour nor the focus rule. Asserting it here is what lets the call sites
/// stop repeating it.
void _entryPointTests() {
  Future<bool?> run(
    WidgetTester tester, {
    required Future<void> Function(WidgetTester) dismiss,
  }) async {
    bool? answer;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                answer = await showMxConfirm(
                  context,
                  title: 'Empty the Trash?',
                  message: 'Everything in it goes for good.',
                  confirmLabel: 'Delete for good',
                  cancelLabel: 'Cancel',
                  variant: MxConfirmDialogVariant.destructive,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await dismiss(tester);
    await tester.pumpAndSettle();

    return answer;
  }

  testWidgets('the confirm button is the only yes', (tester) async {
    final answer = await run(
      tester,
      dismiss: (t) => t.tap(find.text('Delete for good')),
    );

    expect(answer, isTrue);
  });

  testWidgets('cancel is a no', (tester) async {
    final answer = await run(
      tester,
      dismiss: (t) => t.tap(find.text('Cancel')),
    );

    expect(answer, isFalse);
  });

  testWidgets(
    'tapping the barrier is a no, not a null the caller must handle',
    (tester) async {
      final answer = await run(
        tester,
        dismiss: (t) => t.tapAt(const Offset(10, 10)),
      );

      expect(
        answer,
        isFalse,
        reason:
            'the return type is bool, not bool? — a caller cannot forget the '
            '`?? false` that five of them used to write by hand',
      );
    },
  );

  testWidgets('the Android back gesture is a no', (tester) async {
    final answer = await run(
      tester,
      dismiss: (t) async {
        final NavigatorState navigator = t.state(find.byType(Navigator));
        await navigator.maybePop();
      },
    );

    expect(answer, isFalse);
  });
}
