import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_motion_policy.dart';
import 'package:memox/shared/widgets/mx_sheet.dart';

/// Reduced motion has to reach the route, not just the widgets inside it.
///
/// **`AppMotionPolicy.durationOf` could not do this, which is why the policy
/// grew a second answer.** Everything it covers is a widget the app builds and
/// hands a duration to. A sheet animates inside a route the framework drives,
/// and `AnimationController` does **not** zero a duration when
/// `disableAnimations` is set — it scales the velocity. So a user who asked the
/// system to remove animations still got the sheet sliding up, only quicker,
/// which is the motion they turned the setting on to stop.
void main() {
  Future<void> pumpSheetHost(
    WidgetTester tester, {
    required bool disableAnimations,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Builder(
        // `copyWith` on the real data, never a fresh `MediaQueryData`:
        // constructing one zeroes `size` and `padding`.
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: Scaffold(
            body: Builder(
              builder: (inner) => TextButton(
                onPressed: () => showMxSheet<void>(
                  inner,
                  builder: (_) => const Text('sheet body'),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('the sheet is fully in place on the first frame', (tester) async {
    await pumpSheetHost(tester, disableAnimations: true);
    await tester.tap(find.text('open'));
    // One frame to push the route, and nothing more. With a transition still
    // running the body would be off-screen at this point.
    await tester.pump();

    expect(find.text('sheet body'), findsOneWidget);
    final settled = tester.getTopLeft(find.text('sheet body'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('sheet body')),
      settled,
      reason: 'the sheet moved after its first frame, so it animated',
    );
  });

  testWidgets('and still animates when motion is not reduced', (tester) async {
    // The counterpart, so the test above cannot be satisfied by a sheet that
    // simply stopped moving for everybody.
    await pumpSheetHost(tester, disableAnimations: false);
    await tester.tap(find.text('open'));
    await tester.pump();

    final firstFrame = tester.getTopLeft(find.text('sheet body'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('sheet body')),
      isNot(firstFrame),
      reason: 'the sheet arrived in place immediately, so nothing animated',
    );
  });

  testWidgets('the policy names the same flag the widgets read', (
    tester,
  ) async {
    late AnimationStyle? reduced;
    late AnimationStyle? normal;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: Builder(
              builder: (inner) {
                reduced = AppMotionPolicy.animationStyleOf(inner);

                return MediaQuery(
                  data: MediaQuery.of(inner).copyWith(disableAnimations: false),
                  child: Builder(
                    builder: (deepest) {
                      normal = AppMotionPolicy.animationStyleOf(deepest);

                      return const SizedBox.shrink();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(reduced, AnimationStyle.noAnimation);
    // `null`, not a style of our own: the SDK's answer stays the default, so
    // this is not a second place to keep in step with it.
    expect(normal, isNull);
  });
}
