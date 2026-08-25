import 'package:flutter/material.dart';
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
  });
}
