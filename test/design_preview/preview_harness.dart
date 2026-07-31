import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_radius.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../support/golden_density.dart';

/// Design exploration: composition studies under the **production** theme.
///
/// **These are look-alikes, not the app.** `_ReviewScreen`, `_DeckListScreen`
/// and `_SettingsScreen` are private replicas built to argue about colour before
/// the real screens existed. Auditing a replica proves only that the replica is
/// correct — the production screens are audited from
/// `test/visual_audit/screens/audited_screens.dart`, and the coverage gate there
/// is what makes sure none is forgotten. The folder is named `design_preview`
/// rather than `review` so the two are not mistaken for each other, which they
/// were.
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
  // Logical 420x1040, rasterised at [kGoldenDevicePixelRatio]. The layout is
  // unchanged — logical size is physical / dpr — and only the raster got finer.
  tester.view.physicalSize = goldenSurfaceFor(const Size(420, 1040));
  tester.view.devicePixelRatio = kGoldenDevicePixelRatio;
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
    // Selection is a step along the neutral ladder plus a heavier border —
    // never a tint of the verdict's own hue. Label and fill sharing a hue means
    // every point of tint eats the label's contrast: 18% landed at 4.23:1 in
    // dark, 10% at 4.40:1 in light. And an `alphaBlend` produces a colour that
    // is in no palette, which the audit rejects outright — a state layer has to
    // be built from tokens somewhere the palette can see it.
    //
    // **The direction of that step flipped at M4.10p, and the audit is what
    // caught it.** Selection used to fill with `secondaryContainer`. Once the
    // semantic colours came from the design system, light `success` on that
    // ground measured **4.30:1** at 14px — under 4.5 — and
    // `review_screen_preview_test.dart` failed on it.
    //
    // The design system had already answered this: its own `VerdictAction`
    // draws on `--color-surface` and says the fill "stays neutral even on press,
    // because a tint of the verdict's own hue eats the label's contrast at
    // exactly the moment the label matters". So idle now sits on the design's
    // ground and selection steps toward `surfaceMuted` instead of past it —
    // the same direction in both modes, where the old pairing brightened in
    // light and darkened in dark.
    //
    // Measured on every combination: light 5.20 / 5.57 idle, 4.54 / 4.87
    // selected; dark 7.86 / 6.51 idle, 6.44 / 5.33 selected. `secondaryContainer`
    // was the only ground of the five candidates that failed.
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? semantic.surfaceMuted : scheme.surface,
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
        letterSpacing: AppTypography.sectionLabelTracking,
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
