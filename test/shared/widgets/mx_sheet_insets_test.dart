import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_sheet_insets.dart';

/// The one formula three sheets each wrote a version of, and one wrote wrong.
///
/// **The wrong one shipped and looked right in every test that existed.**
/// `starter_install_widget` padded its sheet by `viewInsets.bottom` — the
/// keyboard — on a sheet with no text field, so the term was always zero and
/// there was no `SafeArea` either. Its primary action sat under the Android
/// navigation bar on every device that has one, and nothing was red: a widget
/// test with no `viewPadding` set reproduces exactly the configuration where
/// the bug is invisible.
///
/// So every case here sets `viewPadding`, `viewInsets`, or both, and measures
/// where the content actually ended up.
void main() {
  /// Renders one 40dp box inside the insets, on a surface whose bottom is
  /// obstructed by [viewPadding] and whose keyboard is [viewInsets] tall.
  Future<({Rect content, Rect surface})> layout(
    WidgetTester tester, {
    double viewPadding = 0,
    double viewInsets = 0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 640),
            viewPadding: EdgeInsets.only(bottom: viewPadding),
            viewInsets: EdgeInsets.only(bottom: viewInsets),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: MxSheetInsets(
              child: Container(key: const Key('content'), height: 40),
            ),
          ),
        ),
      ),
    );

    return (
      content: tester.getRect(find.byKey(const Key('content'))),
      surface: tester.getRect(find.byType(MxSheetInsets)),
    );
  }

  testWidgets('the gesture bar does not eat the content', (tester) async {
    // 24dp: Android's gesture bar. The three-button bar is 48.
    final rects = await layout(tester, viewPadding: 24);

    expect(
      rects.surface.bottom - rects.content.bottom,
      moreOrLessEquals(AppSpacing.lg + 24, epsilon: 0.5),
      reason:
          'this is the case the broken sheet was in: keyboard down, system bar '
          'up, and a formula that only knew about the keyboard',
    );
  });

  testWidgets('the three-button bar does not either', (tester) async {
    final rects = await layout(tester, viewPadding: 48);

    expect(
      rects.surface.bottom - rects.content.bottom,
      moreOrLessEquals(AppSpacing.lg + 48, epsilon: 0.5),
    );
  });

  testWidgets('the keyboard is cleared when it is up', (tester) async {
    final rects = await layout(tester, viewInsets: 300, viewPadding: 24);

    expect(
      rects.surface.bottom - rects.content.bottom,
      moreOrLessEquals(AppSpacing.lg + 300, epsilon: 0.5),
    );
  });

  testWidgets('the two are not added together', (tester) async {
    final rects = await layout(tester, viewInsets: 300, viewPadding: 48);

    expect(
      rects.surface.bottom - rects.content.bottom,
      moreOrLessEquals(AppSpacing.lg + 300, epsilon: 0.5),
      reason:
          'a raised keyboard already covers the system bar; summing them lifts '
          'the actions a bar height above the keyboard for no reason',
    );
  });

  testWidgets('with nothing obstructing, it is one plain gutter', (
    tester,
  ) async {
    final rects = await layout(tester);

    expect(
      rects.surface.bottom - rects.content.bottom,
      moreOrLessEquals(AppSpacing.lg, epsilon: 0.5),
    );
  });

  testWidgets('the horizontal and top gutters are the same step', (
    tester,
  ) async {
    final rects = await layout(tester, viewPadding: 24);

    expect(rects.content.left - rects.surface.left, AppSpacing.lg);
    expect(rects.surface.right - rects.content.right, AppSpacing.lg);
    expect(rects.content.top - rects.surface.top, AppSpacing.lg);
  });

  testWidgets('mxSheetBottomObstruction agrees with what the widget draws', (
    tester,
  ) async {
    late double reported;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            viewPadding: EdgeInsets.only(bottom: 48),
          ),
          child: Builder(
            builder: (context) {
              reported = mxSheetBottomObstruction(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(
      reported,
      48,
      reason:
          'the export sheet composes the function directly because it has no '
          'top gutter — the two must not be able to disagree',
    );
  });
}
