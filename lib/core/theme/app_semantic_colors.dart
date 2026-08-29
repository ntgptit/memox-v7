import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_surface_colors.dart';
import 'app_border_colors.dart';

/// The meanings `ColorScheme` has no slot for.
///
/// A `ThemeExtension` rather than a set of globals, because these must change
/// with the theme. A global `successColor` is correct in exactly one
/// brightness, and wrong in the other on every screen at once.
@immutable
final class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.primaryAccent,
    required this.streakContainer,
    required this.onStreakContainer,
    required this.progressTrack,
    required this.progressFill,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.borderDivider,
    required this.borderSelected,
    required this.surfaceEmphasis,
    required this.surfaceSelected,
    required this.surfaceMuted,
    required this.surfaceElevated,
    required this.borderAccent,
    required this.borderSubtle,
    required this.borderControl,
    required this.focusRing,
    required this.secondaryAction,
    required this.disabledSurface,
    required this.onDisabled,
  });

  const AppSemanticColors.light()
    : primaryAccent = AppColors.primaryAccentLight,
      streakContainer = AppColors.streakContainerLight,
      onStreakContainer = AppColors.onStreakContainerLight,
      progressTrack = AppColors.progressTrackLight,
      progressFill = AppColors.progressFillLight,
      success = AppColors.successLight,
      warning = AppColors.warningLight,
      danger = AppColors.dangerLight,
      info = AppColors.infoLight,
      borderDivider = AppBorderColors.borderDividerLight,
      borderSelected = AppBorderColors.borderSelectedLight,
      surfaceEmphasis = AppSurfaceColors.surfaceEmphasisLight,
      surfaceSelected = AppSurfaceColors.surfaceSelectedLight,
      surfaceMuted = AppSurfaceColors.surfaceMutedLight,
      surfaceElevated = AppSurfaceColors.surfaceElevatedLight,
      borderAccent = AppBorderColors.borderAccentLight,
      borderSubtle = AppBorderColors.borderSubtleLight,
      borderControl = AppBorderColors.borderControlLight,
      focusRing = AppBorderColors.focusRingLight,
      secondaryAction = AppColors.secondaryActionLight,
      disabledSurface = AppColors.disabledSurfaceLight,
      onDisabled = AppColors.onDisabledLight;

  const AppSemanticColors.dark()
    : primaryAccent = AppColors.primaryAccentDark,
      streakContainer = AppColors.streakContainerDark,
      onStreakContainer = AppColors.onStreakContainerDark,
      progressTrack = AppColors.progressTrackDark,
      progressFill = AppColors.progressFillDark,
      success = AppColors.successDark,
      warning = AppColors.warningDark,
      danger = AppColors.dangerDark,
      info = AppColors.infoDark,
      borderDivider = AppBorderColors.borderDividerDark,
      borderSelected = AppBorderColors.borderSelectedDark,
      surfaceEmphasis = AppSurfaceColors.surfaceEmphasisDark,
      surfaceSelected = AppSurfaceColors.surfaceSelectedDark,
      surfaceMuted = AppSurfaceColors.surfaceMutedDark,
      surfaceElevated = AppSurfaceColors.surfaceElevatedDark,
      borderAccent = AppBorderColors.borderAccentDark,
      borderSubtle = AppBorderColors.borderSubtleDark,
      borderControl = AppBorderColors.borderControlDark,
      focusRing = AppBorderColors.focusRingDark,
      secondaryAction = AppColors.secondaryActionDark,
      disabledSurface = AppColors.disabledSurfaceDark,
      onDisabled = AppColors.onDisabledDark;

  /// The brand hue as text — a text button, a link. `ColorScheme.primary` is a
  /// fill colour, held dark enough on dark surfaces that it fails AA as a bare
  /// label; this is the variant that passes. See `AppColors.primaryAccentDark`.
  final Color primaryAccent;

  /// The due chip's fill and its label. See `AppColors.streakContainerLight`
  /// for why the label is not the design's own value.
  final Color streakContainer;
  final Color onStreakContainer;

  /// The unfilled part of a progress track, and the filled part below 100%.
  /// At 100% the fill becomes [success] — see `MxProgressBar`.
  final Color progressTrack;
  final Color progressFill;

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  /// Overdue — a review past its day (BR-161 settled that late is a *red*
  /// signal, distinct from due-today's warm one). It **is** [danger]: the
  /// palette spends one red, and a deck that slipped and a destructive action
  /// sharing it is the accepted cost. The alias exists so a call site says
  /// *overdue* and an audit can find every place the state is painted —
  /// which `danger` alone cannot, because it also names delete buttons.
  Color get overdue => danger;

  /// The due chip's fill and label — [streakContainer] and [onStreakContainer]
  /// under the name the call sites mean. The design reuses one warm family
  /// for everything time-pressured; the streak display (Progress) and the due
  /// chip (Library, Study home) both draw from it, so the stored pair keeps
  /// the kit's `--color-streak-container` name and each meaning reads through
  /// its own alias.
  Color get dueContainer => streakContainer;
  Color get onDueContainer => onStreakContainer;

  /// Inset tile, chip, icon container — a step above the card.
  /// See [AppBorderColors.borderDividerLight] — the hairline between rows of one
  /// list, drawn only inside a card.
  final Color borderDivider;

  /// See [AppBorderColors.borderSelectedLight] — the edge a picked card wears.
  final Color borderSelected;

  /// See [AppSurfaceColors.surfaceEmphasisLight] — the callout surface `MxCard.tonal`
  /// fills with.
  final Color surfaceEmphasis;

  /// See [AppSurfaceColors.surfaceSelectedLight] — the fill a picked card wears under
  /// `MxCardSelectionTreatment.tint`.
  final Color surfaceSelected;

  final Color surfaceMuted;

  /// The most prominent surface. In dark this is the fill of a primary action:
  /// the button is the top of the surface ladder rather than a block of colour,
  /// which leaves every saturated hue free to carry meaning.
  final Color surfaceElevated;

  /// The accent hairline — see [AppBorderColors.borderAccentLight].
  final Color borderAccent;

  final Color borderSubtle;

  /// The edge of something a finger acts on — a text field, a tappable row, a
  /// board tile — where the edge is the only thing saying so.
  ///
  /// **A second border token, and the reason is a measurement.** [borderSubtle]
  /// is 1.38:1 against the light page and 2.32:1 against the dark one; WCAG
  /// 1.4.11 asks 3:1 of the visual information required to *identify* a user
  /// interface component. A card is identified by the text inside it and its
  /// subtle edge is decoration, which is the exemption the rule grants. An empty
  /// text field is not: with a placeholder and nothing else, its border is the
  /// whole statement that there is somewhere to type. Five `guess` option rows
  /// and ten `match` tiles are the same case — their fills sit 1.06:1 and 1.03:1
  /// from the page, so the border is doing all the separating.
  ///
  /// The same edge stated louder, not a different one: same hue, same stroke.
  final Color borderControl;

  /// Input border while focused. Focus shifts hue, never stroke width.
  final Color focusRing;

  /// Label of a secondary (outlined) action.
  final Color secondaryAction;

  /// The fill and the border of a disabled control — a solid, so the same
  /// disabled button is the same colour on a page, on a card and in a dialog.
  /// See `AppColors.disabledSurfaceLight`.
  final Color disabledSurface;

  /// A disabled label or glyph. Translucent, because it has three possible
  /// grounds where [disabledSurface] has one.
  final Color onDisabled;

  @override
  AppSemanticColors copyWith({
    Color? primaryAccent,
    Color? streakContainer,
    Color? onStreakContainer,
    Color? progressTrack,
    Color? progressFill,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? borderDivider,
    Color? borderSelected,
    Color? surfaceEmphasis,
    Color? surfaceSelected,
    Color? surfaceMuted,
    Color? surfaceElevated,
    Color? borderAccent,
    Color? borderSubtle,
    Color? borderControl,
    Color? focusRing,
    Color? secondaryAction,
    Color? disabledSurface,
    Color? onDisabled,
  }) {
    return AppSemanticColors(
      primaryAccent: primaryAccent ?? this.primaryAccent,
      streakContainer: streakContainer ?? this.streakContainer,
      onStreakContainer: onStreakContainer ?? this.onStreakContainer,
      progressTrack: progressTrack ?? this.progressTrack,
      progressFill: progressFill ?? this.progressFill,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      borderDivider: borderDivider ?? this.borderDivider,
      borderSelected: borderSelected ?? this.borderSelected,
      surfaceEmphasis: surfaceEmphasis ?? this.surfaceEmphasis,
      surfaceSelected: surfaceSelected ?? this.surfaceSelected,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      borderAccent: borderAccent ?? this.borderAccent,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderControl: borderControl ?? this.borderControl,
      focusRing: focusRing ?? this.focusRing,
      secondaryAction: secondaryAction ?? this.secondaryAction,
      disabledSurface: disabledSurface ?? this.disabledSurface,
      onDisabled: onDisabled ?? this.onDisabled,
    );
  }

  /// Interpolates every field.
  ///
  /// A field left out of `lerp` snaps instead of animating during a theme
  /// change, and the snap is only visible on the one screen that uses it —
  /// which is why the test compares against a full mid-point rather than
  /// spot-checking a colour.
  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;

    return AppSemanticColors(
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      streakContainer: Color.lerp(streakContainer, other.streakContainer, t)!,
      onStreakContainer: Color.lerp(
        onStreakContainer,
        other.onStreakContainer,
        t,
      )!,
      progressTrack: Color.lerp(progressTrack, other.progressTrack, t)!,
      progressFill: Color.lerp(progressFill, other.progressFill, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      borderDivider: Color.lerp(borderDivider, other.borderDivider, t)!,
      borderSelected: Color.lerp(borderSelected, other.borderSelected, t)!,
      surfaceEmphasis: Color.lerp(surfaceEmphasis, other.surfaceEmphasis, t)!,
      surfaceSelected: Color.lerp(surfaceSelected, other.surfaceSelected, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      borderAccent: Color.lerp(borderAccent, other.borderAccent, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderControl: Color.lerp(borderControl, other.borderControl, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      secondaryAction: Color.lerp(secondaryAction, other.secondaryAction, t)!,
      disabledSurface: Color.lerp(disabledSurface, other.disabledSurface, t)!,
      onDisabled: Color.lerp(onDisabled, other.onDisabled, t)!,
    );
  }
}
