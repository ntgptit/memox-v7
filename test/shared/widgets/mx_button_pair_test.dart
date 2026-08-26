import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_button_pair.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

/// The rule: two buttons offered together are drawn at one size, in either
/// orientation and at every text scale.
///
/// It is a test rather than a review note because the failure is invisible to
/// every other gate the project has. `flutter analyze` and the guard read
/// source text; a golden compares a screen with yesterday's copy of itself, so
/// a mismatch that is wrong from the first render passes forever. What went
/// wrong in the empty library — `Browse starter library` above a visibly
/// narrower `New deck` — is a laid-out rectangle, and only a laid-out rectangle
/// can catch it.
void main() {
  Widget host(
    Widget child, {
    double width = 360,
    double textScale = 1,
  }) => MaterialApp(
    theme: buildLightTheme(),
    home: Builder(
      // `copyWith`, never a fresh `MediaQueryData`: constructing one zeroes
      // `size`, `padding` and `viewInsets`, so the widget under test is told
      // the screen is 0x0 while `tester.view` says otherwise.
      builder: (context) {
        final media = MediaQuery.of(context);

        return MediaQuery(
          // The width is set on both the query and the box: the pair reads
          // the screen to decide whether a row fits (see its doc comment),
          // and the box is what it is then laid out in.
          data: media.copyWith(
            size: Size(width, media.size.height),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Center(
              child: SizedBox(width: width, child: child),
            ),
          ),
        );
      },
    ),
  );

  /// Every button label drew on one line.
  ///
  /// A wrapped label is what a too-narrow row produces, and it is exactly what
  /// no other gate sees: the pair is still "one size", the golden still matches
  /// itself, and nothing overflows — the words simply break.
  void expectNoWrappedLabel(WidgetTester tester) {
    final paragraphs = find.descendant(
      of: find.byType(MxActionButton),
      matching: find.byType(RichText),
    );

    for (var index = 0; index < paragraphs.evaluate().length; index++) {
      final render = tester.renderObject<RenderParagraph>(paragraphs.at(index));
      final text = render.text.toPlainText();
      expect(
        render.size.height,
        lessThan(render.getMaxIntrinsicHeight(double.infinity) * 1.5),
        reason: '"$text" wrapped: the footer is narrower than the pair thinks',
      );
    }
  }

  /// The two buttons' boxes, in tree order.
  List<Size> buttonSizes(WidgetTester tester) {
    final buttons = find.byType(MxActionButton);

    return <Size>[
      for (var index = 0; index < buttons.evaluate().length; index++)
        tester.getSize(buttons.at(index)),
    ];
  }

  void expectOneSize(WidgetTester tester) {
    final sizes = buttonSizes(tester);
    expect(sizes, hasLength(2));
    expect(
      sizes.first.width,
      moreOrLessEquals(sizes.last.width, epsilon: 0.5),
      reason: 'adjacent buttons must be the same width',
    );
    expect(
      sizes.first.height,
      moreOrLessEquals(sizes.last.height, epsilon: 0.5),
      reason: 'adjacent buttons must be the same height',
    );
  }

  const pair = MxButtonPair(
    // Deliberately lopsided labels: equal sizes must come from the layout, not
    // from the two labels happening to measure the same.
    primary: MxActionButton(label: 'Browse starter library', onPressed: null),
    secondary: MxActionButton(
      label: 'New deck',
      onPressed: null,
      variant: MxActionButtonVariant.secondary,
    ),
  );

  group('MxButtonPair', () {
    testWidgets('side by side, the halves are one size', (tester) async {
      await tester.pumpWidget(host(pair));

      expectOneSize(tester);
    });

    testWidgets('stacked by request, the halves are one size', (tester) async {
      await tester.pumpWidget(
        host(
          const MxButtonPair(
            axis: Axis.vertical,
            primary: MxActionButton(
              label: 'Browse starter library',
              onPressed: null,
            ),
            secondary: MxActionButton(
              label: 'New deck',
              onPressed: null,
              variant: MxActionButtonVariant.secondary,
            ),
          ),
        ),
      );

      expectOneSize(tester);
    });

    testWidgets('a line too narrow for a row stacks instead of squeezing', (
      tester,
    ) async {
      await tester.pumpWidget(host(pair, width: 220));

      final sizes = buttonSizes(tester);
      expect(
        sizes.first.width,
        moreOrLessEquals(220, epsilon: 0.5),
        reason:
            'below the threshold the pair stacks, so each half is the '
            'full width rather than half of a line neither label fits',
      );
      expectOneSize(tester);
    });

    testWidgets('the sizes still match when one label wraps at 2.0×', (
      tester,
    ) async {
      await tester.pumpWidget(host(pair, width: 720, textScale: 2));

      expectOneSize(tester);
    });
  });

  group('the pair as its callers draw it', () {
    testWidgets('an empty state with two ways forward draws them one size', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          MxEmptyState(
            title: 'No decks yet',
            message: 'Create a deck to start organizing your cards.',
            actionLabel: 'Browse starter library',
            onAction: () {},
            secondaryActionLabel: 'New deck',
            onSecondaryAction: () {},
          ),
        ),
      );

      expectOneSize(tester);
    });

    testWidgets('a confirm dialog draws cancel and confirm one size', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          MxConfirmDialog(
            title: 'Delete deck?',
            message: 'This deletes 4 sub-decks and 11 cards.',
            confirmLabel: 'Delete deck',
            cancelLabel: 'Cancel',
            variant: MxConfirmDialogVariant.destructive,
            onConfirm: () {},
            onCancel: () {},
          ),
        ),
      );

      expectOneSize(tester);
    });

    testWidgets('a dialog footer stacks, because it is not the screen wide', (
      tester,
    ) async {
      // 393 is the review surface. The dialog's footer is
      // `393 − 2×40 inset − 2×24 actions = 265`, below the 280 a row needs, so
      // the pair must stack. Reading the screen instead gave 361, kept the row,
      // and wrapped both labels to two lines — in every dialog in the app.
      await tester.pumpWidget(
        host(
          const MxConfirmDialog(
            title: 'Delete "Academic Word List"?',
            message: '4 sub-decks and 570 cards go to Trash with it.',
            confirmLabel: 'Move to Trash',
            cancelLabel: 'Cancel',
            variant: MxConfirmDialogVariant.cautious,
            onConfirm: _noop,
            onCancel: _noop,
          ),
          width: 393,
        ),
      );

      final pair = tester.widget<MxButtonPair>(find.byType(MxButtonPair));
      expect(
        pair.availableWidth,
        MxConfirmDialog.footerWidth(tester.element(find.byType(MxButtonPair))),
        reason: 'the dialog must hand the pair its own footer width',
      );
      expect(
        find.byType(Column),
        findsWidgets,
        reason: 'a 265-wide footer cannot hold a row of two 136 buttons',
      );
      expectOneSize(tester);
      expectNoWrappedLabel(tester);
    });

    testWidgets('neither dialog label wraps in Vietnamese', (tester) async {
      // The longer of the two languages the app ships, and the one the review
      // caught the row breaking in first.
      await tester.pumpWidget(
        host(
          const MxConfirmDialog(
            title: 'Xoá "Academic Word List"?',
            message: '4 bộ thẻ con và 570 thẻ vào Trash cùng nó.',
            confirmLabel: 'Chuyển vào Trash',
            cancelLabel: 'Huỷ',
            variant: MxConfirmDialogVariant.cautious,
            onConfirm: _noop,
            onCancel: _noop,
          ),
          width: 393,
        ),
      );

      expectNoWrappedLabel(tester);
    });
  });
}

void _noop() {}
