import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_scroll_end_inset.dart';

void main() {
  testWidgets('a list with no floating action ends 48 above the chrome', (
    tester,
  ) async {
    late double inset;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          inset = mxScrollEndInsetOf(context);
          return const SizedBox();
        },
      ),
    );

    expect(inset, AppSpacing.xxxl);
  });
}
