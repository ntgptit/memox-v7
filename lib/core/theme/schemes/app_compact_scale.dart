import 'package:flutter/material.dart';

import '../foundations/app_breakpoints.dart';
import '../foundations/app_sizing.dart';
import '../foundations/app_spacing.dart';
import '../typography/app_text_styles.dart';
import '../typography/app_typography.dart';

/// The same theme, tightened for a screen narrower than
/// [AppBreakpoints.compact].
///
/// **Body and label text are deliberately untouched.** Scaling readable text
/// down by device width would silently undo `MediaQuery.textScaler` — the user's
/// own accessibility setting — and it undoes it hardest for the people most
/// likely to need it, since a large-text setting is at least as common on a
/// small cheap phone as on a big one. What shrinks here is the type the *app*
/// chose to make oversized, and the padding around it.
///
/// Nothing here touches [AppSizing.touchTarget] either. Material's
/// `VisualDensity.compact` would have been the shorter route and it subtracts
/// 8dp from every button, taking the icon button to 40x40 — under the floor a
/// thumb needs, and under the floor the icon-button theme was measured against.
///
/// **Memoised per base theme, for the reason `buildLightTheme` is.** This runs
/// inside `CompactScaleWidget.build`, under `MaterialApp` — so it re-runs
/// whenever `MemoxApp` rebuilds, not only when the width changes. A fresh
/// `ThemeData` is never `==` to the last one (the component themes hold
/// closures), so on a narrow screen an uncached call would re-notify every
/// `Theme.of` dependent below it and undo the caching one level up.
///
/// An [Expando] rather than a `Map`: it keys on identity, where a map would
/// compute `ThemeData.hashCode` over every component theme on each lookup —
/// paying most of the cost the cache exists to avoid. It also lets a base
/// theme be collected rather than pinning every theme ever passed here, which
/// matters in a test run that builds hundreds.
ThemeData applyCompactScale(ThemeData base) {
  final cached = _compactScaleCache[base];
  if (cached != null) return cached;

  final scaled = _buildCompactScale(base);
  _compactScaleCache[base] = scaled;

  return scaled;
}

final Expando<ThemeData> _compactScaleCache = Expando<ThemeData>(
  'applyCompactScale',
);

ThemeData _buildCompactScale(ThemeData base) {
  final texts = base.textTheme;
  final styles = base.extension<AppTextStyles>();

  return base.copyWith(
    textTheme: texts.copyWith(
      // The app bar title. At 22 a real deck name truncates to "Academic
      // Word ..." on a 320-wide screen; the name is the one thing that screen
      // is about.
      titleLarge: texts.titleLarge?.copyWith(fontSize: 20),
    ),
    // The study card prompt, the app's one deliberately large style — its own
    // extension slot since it left `headlineMedium`, so the compact pass
    // re-sizes the prompt and no longer touches the M3 rung beside it.
    extensions: <ThemeExtension<Object?>>[
      ...base.extensions.values.where((ext) => ext is! AppTextStyles),
      if (styles != null)
        styles.copyWith(
          cardPrompt: styles.cardPrompt.copyWith(
            fontSize: AppTypography.compactCardPromptSize,
          ),
        ),
    ],
    listTileTheme: base.listTileTheme.copyWith(
      // Horizontal only. The vertical rhythm is what keeps a row tappable.
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    ),

    // Buttons keep their height and lose horizontal padding, which is the
    // opposite of what "make the button smaller" would do and the only version
    // that helps.
    //
    // Measured: four study actions in a row at 320 give each button 68px. At
    // 24 a side the padding takes 48 of that and leaves 20 for the label, so
    // "Again" renders as "Ag" and the rest break mid-word — at normal text
    // scale, with no overflow and no exception. At 12 a side the label gets 44.
    filledButtonTheme: FilledButtonThemeData(
      style: base.filledButtonTheme.style?.copyWith(padding: _compactPadding),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style?.copyWith(padding: _compactPadding),
    ),
    // No `textButtonTheme` clause. The app's text button is a zero-padding
    // link (`buildTextButtonTheme`) — there is no horizontal padding to give
    // back, and handing it the buttons' compact padding would indent the one
    // control whose whole point is sitting flush with the column.
  );
}

/// Height is untouched: `minimumSize` still carries
/// [AppSizing.touchTarget].
const WidgetStatePropertyAll<EdgeInsets> _compactPadding =
    WidgetStatePropertyAll<EdgeInsets>(
      EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
    );
