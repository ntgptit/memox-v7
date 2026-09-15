import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

/// The stroke scale, and the one fact that lets a `Border.all(color:)` omit
/// its width without leaving the token system.
///
/// **A20.1 P2-09.** Two `Border.all` sites name no width (`mx_card.dart`,
/// `card_history_event_widget.dart`) and the analyzer refuses
/// `width: AppStroke.hairline` there as a redundant argument. The omission is
/// therefore only safe while Flutter's default *is* the hairline — which this
/// test pins, so an SDK that moved the default would fail here rather than
/// silently redraw every hairline in the app.
void main() {
  test('Flutter\'s default border width is the hairline token', () {
    expect(const BorderSide().width, AppStroke.hairline);
    expect(Border.all().top.width, AppStroke.hairline);
  });

  test(
    'the scale is hairline < control < focus, and the spinner stroke is a decision',
    () {
      expect(AppStroke.hairline, lessThan(AppStroke.control));
      expect(AppStroke.control, lessThan(AppStroke.focus));
      expect(AppStroke.selectionControl, AppStroke.focus);
      // Material's 48 dp ring uses 4; the 16 dp spinner inside a button uses
      // half of that, and the number is named rather than typed.
      expect(AppStroke.indicator, 2);
      expect(AppStroke.indicator, lessThan(4));
    },
  );
}
