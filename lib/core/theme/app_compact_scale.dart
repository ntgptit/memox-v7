import 'package:flutter/material.dart';

import 'app_breakpoints.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

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
/// Nothing here touches [AppSpacing.minimumTouchTarget] either. Material's
/// `VisualDensity.compact` would have been the shorter route and it subtracts
/// 8dp from every button, taking the icon button to 40x40 — under the floor a
/// thumb needs, and under the floor the icon-button theme was measured against.
ThemeData applyCompactScale(ThemeData base) {
  final texts = base.textTheme;

  return base.copyWith(
    textTheme: texts.copyWith(
      // The app bar title. At 22 a real deck name truncates to "Academic
      // Word ..." on a 320-wide screen; the name is the one thing that screen
      // is about.
      titleLarge: texts.titleLarge?.copyWith(fontSize: 20),
      // The review card prompt, the app's one deliberately large style.
      headlineMedium: texts.headlineMedium?.copyWith(
        fontSize: AppTypography.compactCardPromptSize,
      ),
    ),
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
    // Measured: four review actions in a row at 320 give each button 68px. At
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
/// [AppSpacing.minimumTouchTarget].
const WidgetStatePropertyAll<EdgeInsets> _compactPadding =
    WidgetStatePropertyAll<EdgeInsets>(
      EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
    );
