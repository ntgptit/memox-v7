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

    testWidgets('stacked, the pair is content-width and centred - '
        'not two full-bleed slabs', (tester) async {
      // Owner call, 2026-08-28: when the row cannot happen, the buttons take
      // the wider one's own width and sit centred on the line, because two
      // screen-wide slabs read as a wall rather than a choice.
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

      final pairBox = tester.getRect(find.byType(MxButtonPair));
      final top = tester.getRect(find.byType(MxActionButton).at(0));
      expect(top.width, lessThan(pairBox.width - 40));
      expect(top.center.dx, moreOrLessEquals(pairBox.center.dx, epsilon: 0.5));
    });

    testWidgets('it stacks only when a longest word will not fit', (
      tester,
    ) async {
      // **The threshold moved, on the project owner's call.** It used to be the
      // whole label: a row was abandoned the moment either button could not
      // draw its label in full at half the line. That is why a delete dialog on
      // a 393dp screen came out as two stacked buttons — `Move to Trash` wants
      // more than half a 265dp footer — and two stacked buttons cost two
      // heights plus a gap to avoid a wrap inside one.
      //
      // The test is the longest *word* now, because a wrapped label is readable
      // and a label cut mid-word is not. 120dp cannot hold `library` beside
      // `deck` at half each, so this stacks.
      await tester.pumpWidget(host(pair, width: 120));

      final sizes = buttonSizes(tester);
      expect(
        sizes.first.width,
        moreOrLessEquals(120, epsilon: 0.5),
        reason: 'stacked, so each half takes the whole line',
      );
      expectOneSize(tester);
    });

    testWidgets('a line that fits both longest words stays a row', (
      tester,
    ) async {
      // The width the old rule stacked at, and the reason this change exists.
      await tester.pumpWidget(host(pair, width: 220));

      expect(
        tester.getTopLeft(find.byType(MxActionButton).at(0)).dy,
        moreOrLessEquals(
          tester.getTopLeft(find.byType(MxActionButton).at(1)).dy,
          epsilon: 0.5,
        ),
        reason: 'both buttons sit on one line even though a label must wrap',
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

    testWidgets('a dialog whose labels fit keeps the row', (tester) async {
      // **The case this widget was rewritten for.** `Delete tag` needs 117.7
      // and `Cancel` 95.6, so a row of two 117.7 halves needs 243.4 — inside
      // the dialog's 265 footer with room to spare. The previous threshold
      // compared that footer against a constant sized for `Export 128 cards`
      // (136 each, 280 the pair) and stacked anyway, costing 56px of height on
      // a dialog that never needed it, and drawing each button 265 wide for a
      // 118-wide label.
      await tester.pumpWidget(
        host(
          const MxConfirmDialog(
            title: 'Delete tag?',
            message: '"động từ" will be removed from 42 cards.',
            confirmLabel: 'Delete tag',
            cancelLabel: 'Cancel',
            variant: MxConfirmDialogVariant.destructive,
            onConfirm: _noop,
            onCancel: _noop,
          ),
          width: 393,
        ),
      );

      final sizes = buttonSizes(tester);
      expect(
        tester.getTopLeft(find.byType(MxActionButton).at(0)).dy,
        tester.getTopLeft(find.byType(MxActionButton).at(1)).dy,
        reason: 'both labels fit, so the pair must be a row, not a stack',
      );
      expect(
        sizes.first.width,
        lessThan(200),
        reason: 'a row splits the footer; 265 wide would mean it stacked',
      );
      expectOneSize(tester);
      expectNoWrappedLabel(tester);
    });

    testWidgets('a dialog whose labels do not fit wraps rather than stacks', (
      tester,
    ) async {
      // **This test asserted the opposite, and the assertion was the design.**
      // 393 is the review surface, so the dialog's footer is
      // `393 − 2×40 inset − 2×24 actions = 265`; `Move to Trash` needs 145.3,
      // so a row of two full labels needs 298.6 and the pair used to stack.
      //
      // The project owner looked at the result and rejected it: two rows of
      // buttons cost more room than one row with a wrapped label, and a choice
      // reads as a choice when the two options are side by side. A row it is,
      // and `Move to Trash` takes two lines inside its own button.
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

      expect(
        tester.getTopLeft(find.byType(MxActionButton).at(0)).dy,
        moreOrLessEquals(
          tester.getTopLeft(find.byType(MxActionButton).at(1)).dy,
          epsilon: 0.5,
        ),
        reason: 'one row: the two options belong beside each other',
      );
      expectOneSize(tester);
    });

    testWidgets('the Vietnamese dialog is a row too', (tester) async {
      // The longer of the two languages the app ships. It used to assert that
      // neither label wrapped, which was the old rule's whole point; wrapping
      // is the accepted cost of the row now, so what is checked is the row.
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

      expect(
        tester.getTopLeft(find.byType(MxActionButton).at(0)).dy,
        moreOrLessEquals(
          tester.getTopLeft(find.byType(MxActionButton).at(1)).dy,
          epsilon: 0.5,
        ),
      );
      expectOneSize(tester);
    });
  });
}

void _noop() {}
