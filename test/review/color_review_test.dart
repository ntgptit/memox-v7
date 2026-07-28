@Tags(<String>['golden', 'review'])
library;

/// Colour review harness for M3.5a.
///
/// **Test-only, and deliberately not part of the design system.** It renders
/// the *same* composition under four palettes so a direction can be chosen by
/// looking at a screen rather than at a swatch grid. A swatch grid answers
/// "are these colours nice"; the real question is "does the vocabulary card
/// stay the most prominent thing when every control is on screen at once", and
/// only a composition can answer that.
///
/// Typography, spacing, radius, viewport, locale and copy are identical across
/// all eight renders, so the only variable is colour.
///
/// Nothing here touches the production palette or the production goldens.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_radius.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/core/theme/app_typography.dart';

import 'review_palettes.dart';

void main() {
  for (final candidate in reviewCandidates) {
    for (final isDark in <bool>[false, true]) {
      final mode = isDark ? 'dark' : 'light';
      final slug = candidate.name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');

      testWidgets('${candidate.name} — $mode', (tester) async {
        tester.view.physicalSize = const Size(420, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _Harness(
            palette: isDark ? candidate.dark : candidate.light,
            label: '${candidate.name} · ${mode.toUpperCase()}',
          ),
        );
        // Not pumpAndSettle: the loading spinner never settles.
        await tester.pump(const Duration(milliseconds: 250));

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/${slug}_$mode.png'),
        );
      });
    }
  }
}

/// Builds a full Material theme from a flat palette, so every widget below
/// resolves its colours the way the real app would.
ThemeData _themeFrom(ReviewPalette p, {required bool isDark}) {
  final base = ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    useMaterial3: true,
    fontFamily: AppTypography.bodyFamily,
  );

  return base.copyWith(
    scaffoldBackgroundColor: p.background,
    textTheme: AppTypography.buildTextTheme(
      base.textTheme,
    ).apply(bodyColor: p.textPrimary, displayColor: p.textPrimary),
    colorScheme: base.colorScheme.copyWith(
      primary: p.primary,
      onPrimary: p.onPrimary,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      outline: p.borderSubtle,
      outlineVariant: p.borderSubtle,
      error: p.danger,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.buildTextTheme(
        base.textTheme,
      ).titleLarge?.copyWith(color: p.textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      hintStyle: TextStyle(color: p.textSecondary),
      enabledBorder: _border(p.borderSubtle),
      border: _border(p.borderSubtle),
      focusedBorder: _border(p.focusRing),
    ),
  );
}

OutlineInputBorder _border(Color c) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(AppRadius.md),
  borderSide: BorderSide(color: c, width: 1.5),
);

class _Harness extends StatelessWidget {
  const _Harness({required this.palette, required this.label});

  final ReviewPalette palette;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark =
        ThemeData.estimateBrightnessForColor(palette.background) ==
        Brightness.dark;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _themeFrom(palette, isDark: isDark),
      home: _Composition(palette: palette, label: label),
    );
  }
}

class _Composition extends StatelessWidget {
  const _Composition({required this.palette, required this.label});

  final ReviewPalette palette;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Icon(Icons.more_horiz, color: p.textSecondary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: t.bodySmall?.copyWith(color: p.textSecondary)),
            const SizedBox(height: AppSpacing.md),

            // Progress + info indicator.
            Row(
              children: <Widget>[
                Text(
                  '3 of 20 · 12 due today',
                  style: t.bodyMedium?.copyWith(color: p.textSecondary),
                ),
                const Spacer(),
                Icon(Icons.bolt, size: 16, color: p.info),
                const SizedBox(width: 4),
                Text(
                  '7-day streak',
                  style: t.bodySmall?.copyWith(color: p.info),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // THE FLASHCARD. This must stay the most prominent thing on screen.
            _Surface(
              p: p,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ephemeral',
                    style: t.headlineMedium?.copyWith(color: p.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'adjective · lasting for a very short time',
                    style: t.bodyMedium?.copyWith(color: p.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '“Fashions are ephemeral: new ones regularly '
                    'displace the old.”',
                    style: t.bodyMedium?.copyWith(color: p.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // The two review actions — the decision the user is making.
            Row(
              children: <Widget>[
                Expanded(
                  child: _Action(
                    p: p,
                    label: 'Forgotten',
                    tint: p.danger,
                    filled: false,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _Action(
                    p: p,
                    label: 'Remembered',
                    tint: p.success,
                    filled: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Primary and secondary chrome actions.
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                child: const Text('Continue session'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.secondaryAction,
                  side: BorderSide(color: p.borderSubtle, width: 1.5),
                  minimumSize: const Size(64, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text('End session'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Inputs, resting and focused.
            const TextField(
              decoration: InputDecoration(hintText: 'Search this deck'),
            ),
            const SizedBox(height: AppSpacing.sm),
            const _FocusedField(),
            const SizedBox(height: AppSpacing.lg),

            // The three states, side by side, so competition between them is
            // visible rather than assumed.
            _Status(
              p: p,
              tint: p.success,
              icon: Icons.check_circle_outline,
              text: 'Saved to your deck',
            ),
            const SizedBox(height: AppSpacing.sm),
            _Status(
              p: p,
              tint: p.warning,
              icon: Icons.schedule,
              text: '4 cards due in the next hour',
            ),
            const SizedBox(height: AppSpacing.sm),
            _Status(
              p: p,
              tint: p.danger,
              icon: Icons.error_outline,
              text: 'Could not sync — changes are saved locally',
            ),
          ],
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.p, required this.child});

  final ReviewPalette p;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: p.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: p.borderSubtle),
    ),
    child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: child),
  );
}

/// The review verdict buttons: tinted outline, not a filled block, so two of
/// them side by side do not turn the screen into a traffic light.
class _Action extends StatelessWidget {
  const _Action({
    required this.p,
    required this.label,
    required this.tint,
    required this.filled,
  });

  final ReviewPalette p;
  final String label;
  final Color tint;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: filled ? tint : p.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: tint, width: 1.5),
    ),
    child: Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: filled ? p.onPrimary : tint),
    ),
  );
}

class _Status extends StatelessWidget {
  const _Status({
    required this.p,
    required this.tint,
    required this.icon,
    required this.text,
  });

  final ReviewPalette p;
  final Color tint;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Icon(icon, size: 18, color: tint),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: p.textSecondary),
        ),
      ),
    ],
  );
}

class _FocusedField extends StatefulWidget {
  const _FocusedField();

  @override
  State<_FocusedField> createState() => _FocusedFieldState();
}

class _FocusedFieldState extends State<_FocusedField> {
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
    decoration: const InputDecoration(hintText: 'Search (focused)'),
  );
}
