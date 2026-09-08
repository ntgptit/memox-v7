import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/widgets/items/guess_option_item_widget.dart';

import '../../../support/android_text_scaler.dart';
import 'support/study_widget_harness.dart';

/// `AppGuessOption.naturalHeightOf` must describe the row the app builds.
///
/// **It is a budget, not a decoration.** `guess_question_section_widget.dart`
/// subtracts the five returned heights from the viewport to decide how tall the
/// prompt card may be, and hands each row its own value as a `minHeight`. A
/// helper that over-states takes that height off the card for nothing; one that
/// under-states puts the options into a scroll on a screen whose whole point is
/// that all five are visible at once (BR-121).
///
/// **The bug this file exists for was an over-statement, and only a non-linear
/// scaler can see it.** The floor was written
/// `MediaQuery.textScalerOf(context).scale(rowMinHeight)` — 48 passed through
/// the text scaler. 48 is a touch target, not a font size. Under
/// `TextScaler.linear(2.0)` that returns 96 while the text also doubles, so the
/// content term usually wins and the mistake hides; under Android's real curve
/// the table compresses large sizes, so `scale(48)` lands *above* two lines of
/// scaled body text and the floor wins when it should not.
void main() {
  /// The helper's answer and the widget's actual height, measured together
  /// under one `MediaQuery` so neither can be read at a scale the other did not
  /// see.
  Future<({double helper, double rendered})> measure(
    WidgetTester tester, {
    required String text,
    required TextScaler scaler,
    double width = 360,
    GuessOptionState state = GuessOptionState.correct,
  }) async {
    late double helper;

    await tester.pumpWidget(
      wrapForTest(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: Builder(
              builder: (BuildContext context) {
                helper = AppGuessOption.naturalHeightOf(
                  context,
                  text,
                  width: width,
                );

                return GuessOptionItemWidget(
                  text: text,
                  state: state,
                  onTap: () {},
                );
              },
            ),
          ),
        ),
        isScrollable: false,
        textScaler: scaler,
      ),
    );
    // The row is an `AnimatedContainer`; settle so its height is the target
    // rather than a frame of the implicit animation.
    await tester.pumpAndSettle();

    return (
      helper: helper,
      rendered: tester.getSize(find.byType(GuessOptionItemWidget)).height,
    );
  }

  // Short enough to stay on one line at any width used here.
  const String shortText = 'Sea';
  // Long enough to wrap several times at 360 and much more when scaled.
  const String longText =
      'Deep sleep / Giấc ngủ sâu (Danh từ, trạng thái ngủ ngon '
      'không bị gián đoạn trong nhiều giờ liền)';

  group('the floor is a touch target, so it does not scale', () {
    testWidgets('short text sits on the floor, and the helper says so', (
      tester,
    ) async {
      final result = await measure(
        tester,
        text: shortText,
        scaler: TextScaler.noScaling,
      );

      // The row the widget builds: `MxPressable`'s 48 around the padding and
      // the text — and **exactly** that since M100.63, because a resting row
      // draws no stroke and a verdict draws its one outside the box. The row is
      // the touch target, not the touch target plus a border.
      expect(result.rendered, AppGuessOption.rowMinHeight);
      expect(result.helper, result.rendered);
    });

    testWidgets('and the non-linear curve never inflates it', (tester) async {
      // **The regression, stated as the two numbers that used to disagree.**
      // At Android's 2.0 setting `scale(48)` is about 64.3, because 48 sits in
      // the part of the table where growth has already fallen off. The old
      // floor therefore reserved ~64 for a row the widget builds at the height
      // of its scaled text — and five of those came off the prompt card.
      const AndroidTextScaler scaler = AndroidTextScaler.largest;
      final double scaledFloor = scaler.scale(AppGuessOption.rowMinHeight);

      final result = await measure(tester, text: shortText, scaler: scaler);

      expect(
        scaledFloor,
        greaterThan(AppGuessOption.rowMinHeight),
        reason: 'the curve must actually inflate 48, or this proves nothing',
      );
      expect(
        result.helper,
        lessThan(scaledFloor),
        reason: 'the old floor is exactly what must not come back',
      );
      // What it must be instead: the row the widget renders.
      expect(result.helper, result.rendered);
    });

    testWidgets('the floor still holds when the text is tiny', (tester) async {
      // A row shorter than a fingertip is still a fingertip. Nothing here may
      // return less than the constraint the widget applies.
      final result = await measure(
        tester,
        text: shortText,
        scaler: TextScaler.noScaling,
        width: 600,
      );

      expect(result.helper, greaterThanOrEqualTo(AppGuessOption.rowMinHeight));
      expect(result.rendered, AppGuessOption.rowMinHeight);
      expect(result.helper, result.rendered);
    });
  });

  group('text geometry still scales', () {
    testWidgets('wrapped text grows with the curve, past the floor', (
      tester,
    ) async {
      final plain = await measure(
        tester,
        text: longText,
        scaler: TextScaler.noScaling,
      );
      final scaled = await measure(
        tester,
        text: longText,
        scaler: AndroidTextScaler.largest,
      );

      expect(plain.helper, greaterThan(AppGuessOption.rowMinHeight));
      expect(
        scaled.helper,
        greaterThan(plain.helper),
        reason: 'the painter must still be handed the real TextScaler',
      );
      expect(scaled.helper, scaled.rendered);
    });

    testWidgets('and at the middle step of the curve too', (tester) async {
      final scaled = await measure(
        tester,
        text: longText,
        scaler: AndroidTextScaler.large,
      );
      final largest = await measure(
        tester,
        text: longText,
        scaler: AndroidTextScaler.largest,
      );

      expect(scaled.helper, scaled.rendered);
      expect(largest.helper, greaterThan(scaled.helper));
    });
  });

  group('the helper agrees with the rendered row', () {
    // The verdict states draw `AppStroke.control`, which is the width the
    // helper's `rowBorder` assumes — so for those the two are exactly equal.
    for (final GuessOptionState state in <GuessOptionState>[
      GuessOptionState.correct,
      GuessOptionState.chosenWrong,
    ]) {
      testWidgets('exactly, for $state', (tester) async {
        for (final (String text, TextScaler scaler) in <(String, TextScaler)>[
          (shortText, TextScaler.noScaling),
          (shortText, AndroidTextScaler.large),
          (shortText, AndroidTextScaler.largest),
          (longText, TextScaler.noScaling),
          (longText, AndroidTextScaler.large),
          (longText, AndroidTextScaler.largest),
        ]) {
          final result = await measure(
            tester,
            text: text,
            scaler: scaler,
            state: state,
          );

          expect(
            result.helper,
            result.rendered,
            reason: '$state · $scaler · "${text.substring(0, 3)}…"',
          );
        }
      });
    }

    // **`open` and `dimmed` are exact too since M100.63.** They used to be a
    // stroke short of it: they drew a hairline where the helper's `rowBorder`
    // assumed a verdict's heavier stroke, so the helper was a documented
    // ceiling for four rows out of five. Now no state puts a stroke in the
    // layout — resting draws none and a verdict draws its own outside the box —
    // so the ceiling is gone and with it the only place this helper was allowed
    // to be approximately right.
    for (final GuessOptionState state in <GuessOptionState>[
      GuessOptionState.open,
      GuessOptionState.dimmed,
    ]) {
      testWidgets('exactly, for $state', (tester) async {
        for (final TextScaler scaler in <TextScaler>[
          TextScaler.noScaling,
          AndroidTextScaler.large,
          AndroidTextScaler.largest,
        ]) {
          final result = await measure(
            tester,
            text: longText,
            scaler: scaler,
            state: state,
          );

          expect(result.helper, result.rendered, reason: '$state · $scaler');
        }
      });
    }
  });
}
