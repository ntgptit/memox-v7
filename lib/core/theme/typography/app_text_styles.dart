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
  const AppTextStyles({
    required this.cardPrompt,
    required this.sectionLabel,
    required this.sectionLabelSmall,
    required this.stateChipLabel,
    required this.listHeading,
    required this.heroNumeral,
    required this.listRowTitle,
    required this.optionRowTitle,
    required this.optionRowDescription,
  });

  /// Both styles, derived from the built [texts] so they inherit whatever the
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
      cardPrompt: AppTypography.withWeight(promptBase, FontWeight.w600),
      sectionLabel: (texts.labelMedium ?? const TextStyle()).copyWith(
        letterSpacing: AppTypography.sectionLabelTracking,
      ),
      sectionLabelSmall: (texts.labelSmall ?? const TextStyle()).copyWith(
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
      // re-set its weight would pin it against `applyBoldText`, which rebuilds
      // these styles from already-emboldened rungs.
      heroNumeral: (texts.displayLarge ?? const TextStyle()).copyWith(
        height: AppTypography.heroNumeralCapTrim,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
      listRowTitle: AppTypography.withWeight(
        (texts.bodyMedium ?? const TextStyle()).copyWith(
          height: AppTypography.listRowTitleHeight,
          letterSpacing: AppTypography.listRowTitleTracking,
        ),
        FontWeight.w600,
      ),
      // OptionRow's title: `titleSmall` (body-14 at semibold, GC-4) tracked at
      // the kit's own -0.1 — a value no scale rung carries.
      optionRowTitle: (texts.titleSmall ?? const TextStyle()).copyWith(
        letterSpacing: AppTypography.optionRowTitleTracking,
      ),
      // OptionRow's description: `bodySmall` (caption-12 at body weight, GC-4)
      // led at the kit's own 1.45 rather than the caption rung's 1.4.
      optionRowDescription: (texts.bodySmall ?? const TextStyle()).copyWith(
        height: AppTypography.optionRowDescriptionHeight,
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

  /// [sectionLabel] one rung down — the overline above a study face or under a
  /// toolbar, where `label-md` would out-weigh the content it introduces. Found
  /// as four hand-assembled copies (one spelling the tracking token as a bare
  /// `1.1`) when M99.65 clustered the app's text restyles.
  final TextStyle sectionLabelSmall;

  /// The uppercase state word inside a card tile's chip — `label-sm` opened
  /// by its own tracking and set at the emphatic 600.
  final TextStyle stateChipLabel;

  /// The toolbar heading over a list — [sectionLabel]'s tracking swapped for
  /// `listHeadingTracking` and the weight raised to the emphatic 600.
  final TextStyle listHeading;

  /// The one huge number a summary leads with: the stat rung (`displayLarge`,
  /// 40/600), cap-trimmed and tabular. **Moving it here fixed the twelfth
  /// instance of the weight-without-axis bug** — the style used to be
  /// assembled per-site with a bare `fontWeight: heroNumeralWeight`, which
  /// declared the weight and painted the rung's default.
  final TextStyle heroNumeral;

  /// The title of a content row (`MxListRow`): `body-md` at the emphatic 600,
  /// closed up by `listRowTitleTracking` and set on the row's own leading.
  /// Colour stays with the caller — `AppInk.stated` at the row.
  final TextStyle listRowTitle;

  /// The option row's title — see [AppTypography.optionRowTitleTracking].
  final TextStyle optionRowTitle;

  /// The option row's description — see
  /// [AppTypography.optionRowDescriptionHeight].
  final TextStyle optionRowDescription;

  @override
  AppTextStyles copyWith({
    TextStyle? cardPrompt,
    TextStyle? sectionLabel,
    TextStyle? sectionLabelSmall,
    TextStyle? stateChipLabel,
    TextStyle? listHeading,
    TextStyle? heroNumeral,
    TextStyle? listRowTitle,
    TextStyle? optionRowTitle,
    TextStyle? optionRowDescription,
  }) => AppTextStyles(
    cardPrompt: cardPrompt ?? this.cardPrompt,
    sectionLabel: sectionLabel ?? this.sectionLabel,
    sectionLabelSmall: sectionLabelSmall ?? this.sectionLabelSmall,
    stateChipLabel: stateChipLabel ?? this.stateChipLabel,
    listHeading: listHeading ?? this.listHeading,
    heroNumeral: heroNumeral ?? this.heroNumeral,
    listRowTitle: listRowTitle ?? this.listRowTitle,
    optionRowTitle: optionRowTitle ?? this.optionRowTitle,
    optionRowDescription: optionRowDescription ?? this.optionRowDescription,
  );

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) return this;

    return AppTextStyles(
      cardPrompt: TextStyle.lerp(cardPrompt, other.cardPrompt, t)!,
      sectionLabel: TextStyle.lerp(sectionLabel, other.sectionLabel, t)!,
      sectionLabelSmall: TextStyle.lerp(
        sectionLabelSmall,
        other.sectionLabelSmall,
        t,
      )!,
      stateChipLabel: TextStyle.lerp(stateChipLabel, other.stateChipLabel, t)!,
      listHeading: TextStyle.lerp(listHeading, other.listHeading, t)!,
      heroNumeral: TextStyle.lerp(heroNumeral, other.heroNumeral, t)!,
      listRowTitle: TextStyle.lerp(listRowTitle, other.listRowTitle, t)!,
      optionRowTitle: TextStyle.lerp(optionRowTitle, other.optionRowTitle, t)!,
      optionRowDescription: TextStyle.lerp(
        optionRowDescription,
        other.optionRowDescription,
        t,
      )!,
    );
  }
}
