import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_radius.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/core/theme/app_theme.dart';

/// Renders real screens under the **production** theme, light and dark.
///
/// Not a design-system component and not shipped: nothing here is imported by
/// `lib/`. It exists because the questions that decide a palette cannot be
/// answered by a swatch grid or by a contrast number. "Is the flashcard still
/// the most prominent thing when every control is on screen at once" and "do the
/// two verdict buttons read as a traffic light" are answerable only by looking
/// at a whole screen, and only if that screen is built from the same theme the
/// app uses — which is why these pump `buildLightTheme()` / `buildDarkTheme()`
/// rather than a palette table of their own.
///
/// Tagged `review`, so CI can exclude the six images without excluding the
/// component goldens.
Future<void> pumpPreview(
  WidgetTester tester, {
  required bool isDark,
  required Widget child,
  required String goldenName,
}) async {
  tester.view.physicalSize = const Size(420, 1040);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDark ? buildDarkTheme() : buildLightTheme(),
      home: child,
    ),
  );
  await tester.pump(const Duration(milliseconds: 250));

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$goldenName.png'),
  );
}

/// Runs [body] for light and dark under one name.
void previewTest(String name, Widget Function() build) {
  for (final isDark in <bool>[false, true]) {
    final mode = isDark ? 'dark' : 'light';

    testWidgets('$name — $mode', (tester) async {
      await pumpPreview(
        tester,
        isDark: isDark,
        child: build(),
        goldenName: '${name}_$mode',
      );
    });
  }
}

/// A review verdict button — *Forgotten* or *Remembered*.
///
/// Idle is a neutral tile with a semantic border and a restrained semantic
/// label; only the chosen one takes a fill, and even then a soft one. Two
/// saturated blocks side by side turn a study screen into a traffic light, and
/// the pair is meant to read as a question, not as an alarm.
class VerdictAction extends StatelessWidget {
  const VerdictAction({
    required this.label,
    required this.tint,
    required this.isSelected,
    super.key,
  });

  final String label;
  final Color tint;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    const selectedFillAlpha = 0.18;

    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected
            ? Color.alphaBlend(
                tint.withValues(alpha: selectedFillAlpha),
                semantic.surfaceMuted,
              )
            : semantic.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: tint, width: isSelected ? 2 : 1.5),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: tint),
      ),
    );
  }
}

/// Section label above a group of rows.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.1,
      ),
    ),
  );
}

/// A card-shaped container, so every preview builds its surfaces the same way.
class PreviewCard extends StatelessWidget {
  const PreviewCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: semantic.borderSubtle),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}
