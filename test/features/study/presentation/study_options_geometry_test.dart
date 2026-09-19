import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/presentation/screens/study_options_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../domain/support/fake_study_repository.dart';
import 'support/study_widget_harness.dart';

/// The gutter Study Options lays its form out on.
///
/// **Measured, because the screen used to carry two of them.** The body was
/// wrapped in a second `EdgeInsets.all(AppSpacing.lg)` on top of the one
/// `MxContentShell` already applies, so the form sat 32dp in while the app-bar
/// title above it sat 16dp in — two left edges on one screen. Below 360dp the
/// same double inset inverted the compact step-down: 12 + 16 is *more* than the
/// 16 a regular-width screen gets, so the narrowest phone was inset the most.
void main() {
  final english = AppLocalizationsEn();

  Future<void> pumpOptions(WidgetTester tester, {required Size surface}) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studyRepositoryProvider.overrideWithValue(FakeStudyRepository()),
        ],
        // `isScrollable: false`: this is a whole screen with its own `Scaffold`,
        // and the harness's default scroll view would hand it an unbounded
        // height — an assertion rather than a layout.
        child: wrapForTest(
          const StudyOptionsScreen(deckId: 'd1'),
          isScrollable: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the form is inset by one screen gutter, not two', (
    tester,
  ) async {
    await pumpOptions(tester, surface: const Size(393, 852));

    final screen = tester.getRect(find.byType(MaterialApp));
    final field = tester.getRect(find.byType(MxTextField));

    expect(field.left - screen.left, AppSpacing.lg);
    expect(screen.right - field.right, AppSpacing.lg);
  });

  testWidgets('at 320dp the gutter holds, same as at 393dp', (tester) async {
    await pumpOptions(tester, surface: const Size(320, 852));

    final screen = tester.getRect(find.byType(MaterialApp));
    final field = tester.getRect(find.byType(MxTextField));

    // `mxScreenGutter` is `lg` at every width now. With the old double inset
    // this read 28 at 320dp — wider than the 16 a 393dp screen got, which was
    // already the opposite of what a step-down was for; a single inset now
    // reads the same 16 at both widths instead.
    expect(field.left - screen.left, AppSpacing.lg);
  });

  testWidgets(
    'the app-bar title sits one control-gap in, the body one screen-gutter',
    (tester) async {
      await pumpOptions(tester, surface: const Size(393, 852));

      final title = tester.getRect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(english.studyOptionsTitle),
        ),
      );
      final field = tester.getRect(find.byType(MxTextField));

      // **The two edges stopped being the same number at the `MxAppBar`
      // extraction (task-1).** The bar used to inherit `AppBar`'s default
      // `titleSpacing` (16, `kMiddleSpacing`), which happened to equal the
      // body's own `AppSpacing.lg` gutter — one content column by
      // coincidence, not by a shared token. `MxAppBar`'s own compact padding
      // is `AppSpacing.sm` (Requirement 2), a *control*-internal gap rather
      // than a *screen* gutter, so the title now sits 8dp in and the body
      // still sits 16dp in. The gap between them is exactly `lg - sm`.
      expect(title.left, AppSpacing.sm);
      expect(field.left, AppSpacing.lg);
      expect(field.left - title.left, AppSpacing.lg - AppSpacing.sm);
    },
  );
}
