import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_create_action_bar_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_button_pair.dart';

import 'support/card_editor_harness.dart';
import 'support/fake_card_repository.dart';

/// **Create's `Save` is pinned, for the reason edit's is — one step earlier.**
///
/// The pair used to be the last child of the form column, inside the shell's
/// scroll, on the one screen in the app that autofocuses its first field. So
/// the keyboard is up on the first frame, the body has already shrunk, and the
/// primary action of the screen started off screen before the user typed
/// anything (SC-C1-02). The edit half of this claim is measured at
/// `card_editor_layout_test.dart:191-235`; these are the same two measurements
/// on the mode that did not have them, which is why the drift was only ever
/// visible on the mode that did.
void main() {
  Finder footerSave() => find.descendant(
    of: find.byType(CardCreateActionBarWidget),
    matching: find.widgetWithText(MxActionButton, 'Save card'),
  );

  FakeCardRepository seed() {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);

    return repository;
  }

  Future<void> pumpCreate(WidgetTester tester) =>
      pumpCardEditor(tester, seed(), cardId: null);

  group('geometry', () {
    testWidgets('both dispositions sit outside the scroll', (tester) async {
      await pumpCreate(tester);

      // Not `findsNothing` on the scroll itself: the form still scrolls, and
      // that is the point — what must not scroll is the pair.
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(
        find.ancestor(
          of: find.byType(MxButtonPair),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      expect(find.text('Save and add another'), findsOneWidget);
    });

    testWidgets('the footer is pinned to the keyboard edge', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      // The software keyboard a widget test never raises. Create meets the user
      // with it already up, so this is the first frame, not an edge case.
      tester.view.viewInsets = const FakeViewPadding(bottom: 336);
      addTearDown(tester.view.reset);

      await pumpCreate(tester);

      const double keyboardTop = 844 - 336;
      expect(
        tester.getRect(footerSave()).bottom,
        lessThanOrEqualTo(keyboardTop),
      );
      // **Pinned, which is a different claim from visible, and the reason the
      // first line alone would not have caught this.** Measured with the pair
      // back at the end of the scroll: the empty form is short enough that the
      // bar still landed at y 308-396, comfortably above the keyboard — so
      // `<= keyboardTop` was green on the geometry SC-C1-02 is about. What only
      // the footer slot gives is the band sitting *on* that edge; the form
      // grows with a validation error, a long front value or a text scale, and
      // it is that growth the scroll used to push `Save` off screen with.
      expect(
        tester.getRect(find.byType(CardCreateActionBarWidget)).bottom,
        keyboardTop,
      );
    });

    testWidgets('the two dispositions are drawn at one size', (tester) async {
      await pumpCreate(tester);

      final Rect save = tester.getRect(footerSave());
      final Rect addAnother = tester.getRect(
        find.descendant(
          of: find.byType(CardCreateActionBarWidget),
          matching: find.widgetWithText(MxActionButton, 'Save and add another'),
        ),
      );

      // The same `MxButtonPair` argument edit's footer makes: two controls at
      // arm's length read as one choice, and a choice drawn at two sizes has
      // been made for the user by the layout (M99.53).
      expect(save.width, addAnother.width);
      expect(save.height, addAnother.height);
    });
  });
}
