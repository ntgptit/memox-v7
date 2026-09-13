import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_scroll_end_inset.dart';

void main() {
  testWidgets('with a floating action the tail clears it by 48 (D15)', (
    tester,
  ) async {
    late double inset;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: MxScrollEndInsetScope(
          hasFloatingAction: true,
          child: Builder(
            builder: (context) {
              inset = mxScrollEndInsetOf(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(inset, AppSizing.fab + AppSpacing.lg + AppSpacing.xxxl);
  });

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
