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
/// ratio, text scale and locale. Fonts are pinned too, but not here —
/// `test/flutter_test_config.dart` loads Roboto and MaterialIcons from the
/// pinned Flutter SDK before any test runs. Without it `flutter_test`
/// substitutes a placeholder font that draws every glyph as an identical box,
/// and a golden then records the shape of the layout and nothing about the
/// text: a wrong weight, a wrong colour, a truncated label and a line-height
/// regression all produce byte-identical boxes.
///
/// Platform caveat worth knowing before CI: text now renders with real glyphs,
/// but glyph *rasterisation* still differs between operating systems. These
/// were generated on Windows; a Linux runner will produce different
/// antialiasing. M7 must either run this suite on one platform or regenerate
/// per platform — it is tagged `golden` so it can be excluded with
/// `--exclude-tags golden`.
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
    // Proves the bundled faces actually render and that the variable-font
    // weight axis moves. Without this, two families could be declared in
    // pubspec, silently fail to load, and every other golden would still pass
    // on the fallback face.
    'typography': const Scaffold(body: _TypographySpecimen()),
    // The app's hero: a vocabulary prompt in the display face on a card.
    'card_prompt': const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: AppCardSurface(child: _CardPrompt())),
      ),
    ),
    // The input states the palette change was actually about: focus moves the
    // border's hue and leaves its weight alone.
    'input_resting': const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: TextField(decoration: InputDecoration(hintText: 'Search')),
        ),
      ),
    ),
    'input_focused': const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: _AutoFocusedField()),
      ),
    ),
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

/// Takes focus on its first frame, so the golden captures the focused border
/// rather than the resting one.
class _AutoFocusedField extends StatefulWidget {
  const _AutoFocusedField();

  @override
  State<_AutoFocusedField> createState() => _AutoFocusedFieldState();
}

class _AutoFocusedFieldState extends State<_AutoFocusedField> {
  final FocusNode _node = FocusNode();

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    focusNode: _node,
    autofocus: true,
    decoration: const InputDecoration(hintText: 'Search'),
  );
}

/// One line per text role, so a missing family or a stuck weight axis is
/// visible rather than inferred.
class _TypographySpecimen extends StatelessWidget {
  const _TypographySpecimen();

  @override
  Widget build(BuildContext context) {
    final texts = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Ephemeral', style: texts.headlineMedium),
          const SizedBox(height: 12),
          Text('Display / Jakarta 600', style: texts.titleLarge),
          Text('Title / Inter 600', style: texts.titleMedium),
          Text('Body / Inter 400 — 0123456789', style: texts.bodyMedium),
          Text('Label / Inter 600', style: texts.labelLarge),
          Text('Caption / Inter 400', style: texts.bodySmall),
        ],
      ),
    );
  }
}

class _CardPrompt extends StatelessWidget {
  const _CardPrompt();

  @override
  Widget build(BuildContext context) {
    final texts = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('ephemeral', style: texts.headlineMedium),
        const SizedBox(height: 8),
        Text('adjective · /ɪˈfem(ə)rəl/', style: texts.bodyMedium),
      ],
    );
  }
}
