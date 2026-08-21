import 'package:flutter/material.dart';

import 'app_typography.dart';

/// The named styles the M3 `TextTheme` has no slot for.
///
/// A `ThemeExtension`, like `AppSemanticColors`, because they must move with
/// the theme: the compact pass re-sizes the card prompt exactly as it re-sizes
/// `titleLarge`, and a static constant cannot be overridden per screen width.
///
/// **`headlineMedium` carried the card prompt until this class existed**, which
/// put a component's purpose inside a scale rung: any widget reaching for the
/// rung *as a rung* inherited the prompt's 30/−0.5 metrics, and the difference
/// was invisible until such a widget was built. The rung is back on the
/// Material 3 metric and the prompt owns its own name — which is also the
/// design system's own shape: `typography.css` declares `--text-card-prompt`
/// beside the scale, not as one of its steps.
@immutable
final class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({required this.cardPrompt, required this.sectionLabel});

  /// Both styles, derived from the built [texts] so they inherit whatever the
  /// scale inherits (the `inherit` flag, a debug label's lineage) and restate
  /// only what makes them themselves.
  factory AppTextStyles.from(TextTheme texts) {
    final promptBase = (texts.headlineMedium ?? const TextStyle()).copyWith(
      fontFamily: AppTypography.displayFamily,
      fontFamilyFallback: AppTypography.cjkFallback,
      fontSize: AppTypography.cardPromptSize,
      height: AppTypography.cardPromptHeight,
      letterSpacing: AppTypography.cardPromptTracking,
    );

    return AppTextStyles(
      cardPrompt: AppTypography.withWeight(promptBase, FontWeight.w600),
      sectionLabel: (texts.labelMedium ?? const TextStyle()).copyWith(
        letterSpacing: AppTypography.sectionLabelTracking,
      ),
    );
  }

  /// The front of a review card — the one place the app deliberately gets
  /// large, because that text is the task. `--text-card-prompt`:
  /// 30/1.22/−0.5 in the display face, 26 under the compact pass.
  final TextStyle cardPrompt;

  /// The uppercase label above a group of rows — `label-md` opened up by
  /// `--tracking-section-label`. A complete style rather than a tracking
  /// constant callers re-assemble; colour stays with the caller, because the
  /// same heading is brand ink over the Today panel and quiet ink over the
  /// list it titles.
  final TextStyle sectionLabel;

  @override
  AppTextStyles copyWith({TextStyle? cardPrompt, TextStyle? sectionLabel}) =>
      AppTextStyles(
        cardPrompt: cardPrompt ?? this.cardPrompt,
        sectionLabel: sectionLabel ?? this.sectionLabel,
      );

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) return this;

    return AppTextStyles(
      cardPrompt: TextStyle.lerp(cardPrompt, other.cardPrompt, t)!,
      sectionLabel: TextStyle.lerp(sectionLabel, other.sectionLabel, t)!,
    );
  }
}
