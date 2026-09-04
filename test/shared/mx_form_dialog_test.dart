import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_button_pair.dart';
import 'package:memox/shared/widgets/mx_dialog_metrics.dart';
import 'package:memox/shared/widgets/mx_form_dialog.dart';

/// The form-in-a-dialog contract, and one bug it exists to make unwriteable.
///
/// **The bug had no symptom.** `showCardBulkTagPrompt` read
/// `if (name == null) return;` inside its confirm button, so a tag name the
/// value object refused produced a button press with no dialog change, no
/// message, and nothing in a log — indistinguishable from a tap that missed.
/// The first group below is that case, asserted from the outside: press
/// confirm with input the parser refuses, and *something must be on screen*.
void main() {
  Future<String?> pumpPrompt(
    WidgetTester tester, {
    required ({String? value, String? error}) Function(String) parse,
  }) async {
    String? result;
    bool closed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showMxPromptDialog<String>(
                  context,
                  title: 'Add tag',
                  fieldLabel: 'Tag',
                  confirmLabel: 'Add',
                  cancelLabel: 'Cancel',
                  parse: parse,
                );
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(closed, isFalse);

    return result;
  }

  group('a refusal is never silent', () {
    testWidgets('confirm with unparseable input shows the reason and stays', (
      tester,
    ) async {
      await pumpPrompt(
        tester,
        parse: (raw) => (value: null, error: 'Tag name is too long'),
      );

      await tester.enterText(find.byType(TextField), 'x' * 200);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Tag name is too long'), findsOneWidget);
      expect(
        find.byType(AlertDialog),
        findsOneWidget,
        reason: 'the dialog stays so the user can fix what they typed',
      );
    });

    testWidgets('the reason is announced — it is the whole of the feedback', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpPrompt(
        tester,
        parse: (raw) => (value: null, error: 'Tag name is too long'),
      );

      await tester.enterText(find.byType(TextField), 'x' * 200);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text('Tag name is too long')),
        isSemantics(isLiveRegion: true),
        reason:
            'focus does not move and the title does not change, so without a '
            'live region a screen-reader user is told nothing at all',
      );
      handle.dispose();
    });

    testWidgets('a different rule gives a different sentence', (tester) async {
      await pumpPrompt(
        tester,
        parse: (raw) => raw.trim().isEmpty
            ? (value: null, error: 'Tag name cannot be empty')
            : (value: null, error: 'Tag name is too long'),
      );

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(
        find.text('Tag name cannot be empty'),
        findsOneWidget,
        reason:
            'the caller maps the domain problem to copy — a single generic '
            '"invalid" would throw that away',
      );
    });

    testWidgets('the reason clears on the keystroke that fixes it', (
      tester,
    ) async {
      await pumpPrompt(
        tester,
        parse: (raw) => raw.length > 3
            ? (value: null, error: 'Too long')
            : (value: raw, error: null),
      );

      await tester.enterText(find.byType(TextField), 'abcdef');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Too long'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pumpAndSettle();

      expect(
        find.text('Too long'),
        findsNothing,
        reason:
            'a message describing text no longer on screen is worse than '
            'no message',
      );
    });
  });

  group('what it returns', () {
    testWidgets('a successful parse pops with the value', (tester) async {
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showMxPromptDialog<String>(
                    context,
                    title: 'Add tag',
                    fieldLabel: 'Tag',
                    confirmLabel: 'Add',
                    cancelLabel: 'Cancel',
                    parse: (raw) => (value: raw.trim(), error: null),
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
      await tester.enterText(find.byType(TextField), '  grammar  ');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(result, 'grammar');
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('cancel returns null', (tester) async {
      final result = await pumpPrompt(
        tester,
        parse: (raw) => (value: raw, error: null),
      );
      expect(result, isNull);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('the footer is the app\'s button pair, not two loose text buttons', () {
    testWidgets('both actions are the same width and height', (tester) async {
      await pumpPrompt(tester, parse: (raw) => (value: raw, error: null));

      final confirm = tester.getRect(
        find.ancestor(
          of: find.text('Add'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      final cancel = tester.getRect(
        find.ancestor(
          of: find.text('Cancel'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );

      expect(confirm.width, moreOrLessEquals(cancel.width, epsilon: 0.5));
      expect(confirm.height, moreOrLessEquals(cancel.height, epsilon: 0.5));
    });

    testWidgets('the pair is laid out at the footer width, not the screen', (
      tester,
    ) async {
      // **Shown as a route, because that is the only way `insetPadding`
      // applies.** The version of this test that came before rendered the
      // dialog straight into a `Scaffold` body, where `AlertDialog` never sees
      // its own inset — and then asserted that the number handed to the pair
      // equalled the function that produced it. Both sides came from
      // `MediaQuery`, so it passed without the layout being involved at all,
      // and would have kept passing if the footer were the full screen.
      //
      // Measured against the real thing: `393 − 2×inset − 2×actionsInset`.
      // The **view**, not a wrapped `MediaQuery`: `showDialog` pushes onto the
      // Navigator inside `MaterialApp`, which builds its own `MediaQuery` from
      // the view and never sees a wrapper placed above it.
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => MxFormDialog(
                    title: 'Add tag',
                    confirmLabel: 'Add tag to selection',
                    cancelLabel: 'Huỷ bỏ thao tác',
                    onConfirm: () {},
                    onCancel: () {},
                    child: const SizedBox.shrink(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final width = tester.getSize(find.byType(MxButtonPair)).width;

      expect(
        width,
        393 - MxDialogMetrics.inset * 2 - MxDialogMetrics.actionsInset * 2,
        reason: 'the pair must get the dialog footer, not the screen',
      );
      expect(width, lessThan(393));
    });

    testWidgets('a null error adds nothing to the content at all', (
      tester,
    ) async {
      Future<List<Widget>> contentChildren(String? errorMessage) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildLightTheme(),
            home: Scaffold(
              body: MxFormDialog(
                title: 'Add tag',
                confirmLabel: 'Add',
                cancelLabel: 'Cancel',
                errorMessage: errorMessage,
                onConfirm: () {},
                onCancel: () {},
                child: const SizedBox(key: Key('field'), height: 48),
              ),
            ),
          ),
        );

        return tester
            .widget<Column>(
              find
                  .ancestor(
                    of: find.byKey(const Key('field')),
                    matching: find.byType(Column),
                  )
                  .first,
            )
            .children;
      }

      // **Counted rather than measured, and the dialog is why.** `scrollable:
      // true` makes `AlertDialog` fill the surface it is given, so the outer
      // rectangle is the same 600dp with and without the line — the first
      // version of this test measured that and passed on a widget that had not
      // been built yet. What the claim is actually about is whether anything is
      // there.
      expect(
        await contentChildren(null),
        hasLength(1),
        reason:
            'null must add no gap and no box — an empty one would shift the '
            'form the moment a failure arrived',
      );
      expect(await contentChildren('That name is taken'), hasLength(3));
      expect(find.text('That name is taken'), findsOneWidget);
    });
  });
}
