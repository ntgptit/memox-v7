import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_material_roles.dart';
import 'app_surface_colors.dart';
import 'app_border_colors.dart';

/// The meanings `ColorScheme` has no slot for.
///
/// A `ThemeExtension` rather than a set of globals, because these must change
/// with the theme. A global `successColor` is correct in exactly one
/// brightness, and wrong in the other on every screen at once.
///
/// **A status colour comes as a fill and an ink** (M100.86). The fill is the
/// Tokyo handoff's hex, for a dot, a ring or a container; the ink is the same
/// hue solved to read as text. `AppInk` hands features the inks. The reasoning
/// and the measurements are in `AppColors`.
@immutable
final class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.streakContainer,
    required this.onStreakContainer,
    required this.progressTrack,
    required this.progressFill,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.accentInk,
    required this.successInk,
    required this.warningInk,
    required this.dangerInk,
    required this.infoInk,
    required this.inversePrimaryInk,
    required this.secondaryInk,
    required this.tertiaryInk,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.borderOption,
    required this.borderSelected,
    required this.surfaceEmphasis,
    required this.surfaceSelected,
    required this.surfaceMuted,
    required this.borderAccent,
    required this.borderSubtle,
    required this.borderControl,
    required this.disabledSurface,
    required this.onDisabled,
  });

  const AppSemanticColors.light()
    : streakContainer = AppColors.streakContainerLight,
      onStreakContainer = AppColors.onStreakContainerLight,
      progressTrack = AppColors.progressTrackLight,
      progressFill = AppColors.progressFillLight,
      success = AppColors.successLight,
      warning = AppColors.warningLight,
      danger = AppColors.dangerLight,
      info = AppColors.infoLight,
      accentInk = AppColors.accentInkLight,
      successInk = AppColors.successInkLight,
      warningInk = AppColors.warningInkLight,
      dangerInk = AppColors.dangerInkLight,
      infoInk = AppColors.infoInkLight,
      inversePrimaryInk = AppColors.inversePrimaryInk,
      secondaryInk = AppColors.secondaryInkLight,
      tertiaryInk = AppColors.tertiaryInkLight,
      successContainer = AppColors.successContainerLight,
      onSuccessContainer = AppColors.onSuccessContainerLight,
      warningContainer = AppColors.warningContainerLight,
      onWarningContainer = AppColors.onWarningContainerLight,
      infoContainer = AppColors.infoContainerLight,
      onInfoContainer = AppColors.onInfoContainerLight,
      dangerContainer = AppMaterialRoles.errorContainerLight,
      onDangerContainer = AppMaterialRoles.onErrorContainerLight,
      borderOption = AppBorderColors.borderOptionLight,
      borderSelected = AppBorderColors.borderSelectedLight,
      surfaceEmphasis = AppSurfaceColors.surfaceEmphasisLight,
      surfaceSelected = AppSurfaceColors.surfaceSelectedLight,
      surfaceMuted = AppSurfaceColors.surfaceMutedLight,
      borderAccent = AppBorderColors.borderAccentLight,
      borderSubtle = AppBorderColors.borderSubtleLight,
      borderControl = AppBorderColors.borderControlLight,
      disabledSurface = AppColors.disabledSurfaceLight,
      onDisabled = AppColors.onDisabledLight;

  const AppSemanticColors.dark()
    : streakContainer = AppColors.streakContainerDark,
      onStreakContainer = AppColors.onStreakContainerDark,
      progressTrack = AppColors.progressTrackDark,
      progressFill = AppColors.progressFillDark,
      success = AppColors.successDark,
      warning = AppColors.warningDark,
      danger = AppColors.dangerDark,
      info = AppColors.infoDark,
      accentInk = AppColors.accentInkDark,
      successInk = AppColors.successInkDark,
      warningInk = AppColors.warningInkDark,
      dangerInk = AppColors.dangerInkDark,
      infoInk = AppColors.infoInkDark,
      inversePrimaryInk = AppColors.inversePrimaryInk,
      secondaryInk = AppColors.secondaryInkDark,
      tertiaryInk = AppColors.tertiaryInkDark,
      successContainer = AppColors.successContainerDark,
      onSuccessContainer = AppColors.onSuccessContainerDark,
      warningContainer = AppColors.warningContainerDark,
      onWarningContainer = AppColors.onWarningContainerDark,
      infoContainer = AppColors.infoContainerDark,
      onInfoContainer = AppColors.onInfoContainerDark,
      dangerContainer = AppMaterialRoles.errorContainerDark,
      onDangerContainer = AppMaterialRoles.onErrorContainerDark,
      borderOption = AppBorderColors.borderOptionDark,
      borderSelected = AppBorderColors.borderSelectedDark,
      surfaceEmphasis = AppSurfaceColors.surfaceEmphasisDark,
      surfaceSelected = AppSurfaceColors.surfaceSelectedDark,
      surfaceMuted = AppSurfaceColors.surfaceMutedDark,
      borderAccent = AppBorderColors.borderAccentDark,
      borderSubtle = AppBorderColors.borderSubtleDark,
      borderControl = AppBorderColors.borderControlDark,
      disabledSurface = AppColors.disabledSurfaceDark,
      onDisabled = AppColors.onDisabledDark;

  /// The due chip's fill and its label.
  final Color streakContainer;
  final Color onStreakContainer;

  /// The unfilled part of a progress track, and the filled part below 100%.
  /// At 100% the fill becomes [success] — see `MxProgressBar`.
  final Color progressTrack;
  final Color progressFill;

  /// The status **fills** — a dot, a ring, a container's hue. Not for text;
  /// see the inks below.
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  /// The same meanings as **text**. [accentInk] is the brand's; [infoInk] is
  /// the same value under the name a fact-carrying label means.
  final Color accentInk;
  final Color successInk;
  final Color warningInk;
  final Color dangerInk;
  final Color infoInk;

  /// The snackbar's action label on the slate that does not flip.
  final Color inversePrimaryInk;

  /// `secondary` and `tertiary` as text — the support inks `AppInk` names.
  final Color secondaryInk;
  final Color tertiaryInk;

  /// The filled pill a status carries, and its label (M100.21).
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color infoContainer;
  final Color onInfoContainer;

  /// The danger family's container pair, which **is** `error`'s: one red
  /// system, named for the call site that means *late* rather than *fault*.
  final Color dangerContainer;
  final Color onDangerContainer;

  /// Overdue — a review past its day (BR-161). It **is** [danger]; the alias
  /// lets an audit find every place the state is painted.
  Color get overdue => danger;

  /// The due chip's fill and label under the names the call sites mean.
  Color get dueContainer => streakContainer;
  Color get onDueContainer => onStreakContainer;

  /// The resting edge of a selectable card.
  final Color borderOption;

  /// The edge a picked card wears.
  final Color borderSelected;

  /// The callout surface `MxCard.tonal` fills with.
  final Color surfaceEmphasis;

  /// The fill a picked card wears under `MxCardSelectionTreatment.tint`.
  final Color surfaceSelected;

  /// An inset tile, a resting chip, an icon container.
  final Color surfaceMuted;

  /// The accent hairline — the Today card's edge.
  final Color borderAccent;

  /// The decorative hairline — `outlineVariant`.
  final Color borderSubtle;

  /// The edge of something a finger acts on — a text field, a tappable row, a
  /// board tile — where the edge is the only thing saying so. See
  /// `AppBorderColors` for the figures the owner accepted under 3:1.
  final Color borderControl;

  /// The fill and the border of a disabled control — a solid, so the same
  /// disabled button is the same colour on a page, on a card and in a dialog.
  final Color disabledSurface;

  /// A disabled label or glyph. Translucent, because it has three possible
  /// grounds where [disabledSurface] has one.
  final Color onDisabled;

  @override
  AppSemanticColors copyWith({
    Color? streakContainer,
    Color? onStreakContainer,
    Color? progressTrack,
    Color? progressFill,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? accentInk,
    Color? successInk,
    Color? warningInk,
    Color? dangerInk,
    Color? infoInk,
    Color? inversePrimaryInk,
    Color? secondaryInk,
    Color? tertiaryInk,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? dangerContainer,
    Color? onDangerContainer,
    Color? borderOption,
    Color? borderSelected,
    Color? surfaceEmphasis,
    Color? surfaceSelected,
    Color? surfaceMuted,
    Color? borderAccent,
    Color? borderSubtle,
    Color? borderControl,
    Color? disabledSurface,
    Color? onDisabled,
  }) => AppSemanticColors(
    streakContainer: streakContainer ?? this.streakContainer,
    onStreakContainer: onStreakContainer ?? this.onStreakContainer,
    progressTrack: progressTrack ?? this.progressTrack,
    progressFill: progressFill ?? this.progressFill,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    info: info ?? this.info,
    accentInk: accentInk ?? this.accentInk,
    successInk: successInk ?? this.successInk,
    warningInk: warningInk ?? this.warningInk,
    dangerInk: dangerInk ?? this.dangerInk,
    infoInk: infoInk ?? this.infoInk,
    inversePrimaryInk: inversePrimaryInk ?? this.inversePrimaryInk,
    secondaryInk: secondaryInk ?? this.secondaryInk,
    tertiaryInk: tertiaryInk ?? this.tertiaryInk,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    infoContainer: infoContainer ?? this.infoContainer,
    onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    dangerContainer: dangerContainer ?? this.dangerContainer,
    onDangerContainer: onDangerContainer ?? this.onDangerContainer,
    borderOption: borderOption ?? this.borderOption,
    borderSelected: borderSelected ?? this.borderSelected,
    surfaceEmphasis: surfaceEmphasis ?? this.surfaceEmphasis,
    surfaceSelected: surfaceSelected ?? this.surfaceSelected,
    surfaceMuted: surfaceMuted ?? this.surfaceMuted,
    borderAccent: borderAccent ?? this.borderAccent,
    borderSubtle: borderSubtle ?? this.borderSubtle,
    borderControl: borderControl ?? this.borderControl,
    disabledSurface: disabledSurface ?? this.disabledSurface,
    onDisabled: onDisabled ?? this.onDisabled,
  );

  /// Interpolates every field.
  ///
  /// A field left out of `lerp` snaps instead of animating during a theme
  /// change, and the snap is only visible on the one screen that uses it —
  /// which is why the test compares against a full mid-point rather than
  /// spot-checking a colour.
  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;

    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;

    return AppSemanticColors(
      streakContainer: mix(streakContainer, other.streakContainer),
      onStreakContainer: mix(onStreakContainer, other.onStreakContainer),
      progressTrack: mix(progressTrack, other.progressTrack),
      progressFill: mix(progressFill, other.progressFill),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      danger: mix(danger, other.danger),
      info: mix(info, other.info),
      accentInk: mix(accentInk, other.accentInk),
      successInk: mix(successInk, other.successInk),
      warningInk: mix(warningInk, other.warningInk),
      dangerInk: mix(dangerInk, other.dangerInk),
      infoInk: mix(infoInk, other.infoInk),
      inversePrimaryInk: mix(inversePrimaryInk, other.inversePrimaryInk),
      secondaryInk: mix(secondaryInk, other.secondaryInk),
      tertiaryInk: mix(tertiaryInk, other.tertiaryInk),
      successContainer: mix(successContainer, other.successContainer),
      onSuccessContainer: mix(onSuccessContainer, other.onSuccessContainer),
      warningContainer: mix(warningContainer, other.warningContainer),
      onWarningContainer: mix(onWarningContainer, other.onWarningContainer),
      infoContainer: mix(infoContainer, other.infoContainer),
      onInfoContainer: mix(onInfoContainer, other.onInfoContainer),
      dangerContainer: mix(dangerContainer, other.dangerContainer),
      onDangerContainer: mix(onDangerContainer, other.onDangerContainer),
      borderOption: mix(borderOption, other.borderOption),
      borderSelected: mix(borderSelected, other.borderSelected),
      surfaceEmphasis: mix(surfaceEmphasis, other.surfaceEmphasis),
      surfaceSelected: mix(surfaceSelected, other.surfaceSelected),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      borderAccent: mix(borderAccent, other.borderAccent),
      borderSubtle: mix(borderSubtle, other.borderSubtle),
      borderControl: mix(borderControl, other.borderControl),
      disabledSurface: mix(disabledSurface, other.disabledSurface),
      onDisabled: mix(onDisabled, other.onDisabled),
    );
  }
}
