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
/// rung *as a rung* inherited the prompt's metrics, and the difference was
/// invisible until such a widget was built. The rung is the handoff's headline
/// role now and the prompt owns its own name (D13).
@immutable
final class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.cardPrompt,
    required this.sectionLabel,
    required this.stateChipLabel,
    required this.listHeading,
    required this.heroNumeral,
  });

  /// Every style, derived from the built [texts] so they inherit whatever the
  /// scale inherits (the `inherit` flag, a debug label's lineage) and restate
  /// only what makes them themselves.
  factory AppTextStyles.from(TextTheme texts) {
    final promptBase = (texts.headlineMedium ?? const TextStyle()).copyWith(
      fontFamily: AppTypography.family,
      fontFamilyFallback: AppTypography.cjkFallback,
      fontSize: AppTypography.cardPromptSize,
      height: AppTypography.cardPromptHeight,
      letterSpacing: AppTypography.cardPromptTracking,
    );

    return AppTextStyles(
      cardPrompt: AppTypography.withWeight(
        promptBase,
        AppTypography.cardPromptWeight,
      ),
      sectionLabel: (texts.labelSmall ?? const TextStyle()).copyWith(
        letterSpacing: AppTypography.sectionLabelTracking,
      ),
      stateChipLabel: AppTypography.withWeight(
        (texts.labelSmall ?? const TextStyle()).copyWith(
          letterSpacing: AppTypography.stateChipTracking,
        ),
        FontWeight.w600,
      ),
      listHeading: AppTypography.withWeight(
        (texts.labelMedium ?? const TextStyle()).copyWith(
          letterSpacing: AppTypography.listHeadingTracking,
        ),
        FontWeight.w600,
      ),
      // The stat rung's own weight, not a restated one: a named style that
      // sets its weight again pins it against `applyBoldText`, which rebuilds
      // these styles from emboldened rungs.
      heroNumeral: (texts.displayLarge ?? const TextStyle()).copyWith(
        height: AppTypography.heroNumeralCapTrim,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }

  /// The front of a review card — the one place the app deliberately gets
  /// large, because that text is the task. The display size at the headline's
  /// weight and leading (D13); the headline size under the compact pass.
  final TextStyle cardPrompt;

  /// The uppercase overline above a group — the handoff SectionHeader, the
  /// caption (`label-sm`, 12/600/1.4) at `ls-section`. A complete style rather
  /// than a tracking constant callers re-assemble; colour stays with the
  /// caller, because the same heading is brand ink over the Today panel and
  /// quiet ink over the list it titles.
  ///
  /// **One rung since M100.91.** A `sectionLabelSmall` stood beside it for the
  /// overline on a study face or under a toolbar; D1 put both on the 12px
  /// caption, so they resolved to the same metrics and the name was a
  /// distinction nobody could see.
  final TextStyle sectionLabel;

  /// The uppercase state word inside a card tile's chip — `label-sm` at the
  /// label tracking and the emphatic 600.
  final TextStyle stateChipLabel;

  /// The toolbar heading over a list — [sectionLabel]'s tracking swapped for
  /// `listHeadingTracking` and the weight set to the emphatic 600.
  final TextStyle listHeading;

  /// The one huge number a summary leads with: the handoff's stat role
  /// (40/600, D14), cap-trimmed and tabular. **Moving it here fixed the
  /// twelfth instance of the weight-without-axis bug** — the style used to be
  /// assembled per-site with a bare `fontWeight: heroNumeralWeight`, which
  /// declared the weight and painted the rung's default.
  final TextStyle heroNumeral;

  @override
  AppTextStyles copyWith({
    TextStyle? cardPrompt,
    TextStyle? sectionLabel,
    TextStyle? stateChipLabel,
    TextStyle? listHeading,
    TextStyle? heroNumeral,
  }) => AppTextStyles(
    cardPrompt: cardPrompt ?? this.cardPrompt,
    sectionLabel: sectionLabel ?? this.sectionLabel,
    stateChipLabel: stateChipLabel ?? this.stateChipLabel,
    listHeading: listHeading ?? this.listHeading,
    heroNumeral: heroNumeral ?? this.heroNumeral,
  );

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) return this;

    return AppTextStyles(
      cardPrompt: TextStyle.lerp(cardPrompt, other.cardPrompt, t)!,
      sectionLabel: TextStyle.lerp(sectionLabel, other.sectionLabel, t)!,
      stateChipLabel: TextStyle.lerp(stateChipLabel, other.stateChipLabel, t)!,
      listHeading: TextStyle.lerp(listHeading, other.listHeading, t)!,
      heroNumeral: TextStyle.lerp(heroNumeral, other.heroNumeral, t)!,
    );
  }
}
