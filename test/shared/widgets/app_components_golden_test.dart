@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/app_button_widget.dart';
import 'package:memox/shared/widgets/app_card_surface_widget.dart';
import 'package:memox/shared/widgets/app_empty_state_widget.dart';
import 'package:memox/shared/widgets/app_error_state_widget.dart';
import 'package:memox/shared/widgets/app_scaffold_widget.dart';

/// Golden tests for every shared component, light and dark.
///
/// Uses `matchesGoldenFile` from `flutter_test` — no golden_toolkit and no
/// alchemist. Neither is needed for a fixed-size, single-locale snapshot, and
/// adding a dependency to a project this small buys a maintenance burden
/// instead of a capability.
///
/// Everything that can move a pixel is pinned below: surface size, device pixel
/// ratio, text scale and locale. `flutter_test` already substitutes a fixed
/// test font for the platform font, so text renders identically regardless of
/// what is installed on the machine.
///
/// Platform caveat worth knowing before CI: Flutter goldens are not portable
/// across operating systems. These were generated on Windows; a Linux runner
/// will produce different antialiasing. M7 must either run this suite on one
/// platform or regenerate per platform — it is tagged `golden` so it can be
/// excluded with `--exclude-tags golden`.
void main() {
  const surface = Size(360, 640);

  Future<void> pumpGolden(
    WidgetTester tester,
    Widget child, {
    required bool isDark,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        locale: const Locale('en'),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.noScaling),
          child: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// One entry per component. A spinner is deliberately absent: a
  /// `CircularProgressIndicator` is mid-animation at an arbitrary frame, so its
  /// golden would be flaky by construction. Its behaviour is covered by the
  /// semantics test instead.
  final cases = <String, Widget>{
    'card_surface': const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: AppCardSurface(child: Text('Ephemeral')),
      ),
    ),
    'scaffold': const AppScaffoldWidget(title: 'MemoX', body: Text('Body')),
    'button_primary': const Scaffold(
      body: Center(
        child: AppButtonWidget(label: 'Remembered', onPressed: _noop),
      ),
    ),
    'button_secondary': const Scaffold(
      body: Center(
        child: AppButtonWidget(
          label: 'Forgotten',
          onPressed: _noop,
          variant: AppButtonVariant.secondary,
        ),
      ),
    ),
    'button_disabled': const Scaffold(
      body: Center(
        child: AppButtonWidget(label: 'Remembered', onPressed: null),
      ),
    ),
    'empty_state': const Scaffold(
      body: AppEmptyStateWidget(
        title: 'Nothing due today',
        message: 'You have finished every card scheduled for now.',
      ),
    ),
    'error_state': const Scaffold(
      body: AppErrorStateWidget(
        title: 'Something went wrong',
        message: 'This part could not be displayed.',
        retryLabel: 'Try again',
        onRetry: _noop,
      ),
    ),
  };

  for (final entry in cases.entries) {
    for (final isDark in <bool>[false, true]) {
      final mode = isDark ? 'dark' : 'light';

      testWidgets('${entry.key} — $mode', (tester) async {
        await pumpGolden(tester, entry.value, isDark: isDark);

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/${entry.key}_$mode.png'),
        );
      });
    }
  }
}

void _noop() {}
