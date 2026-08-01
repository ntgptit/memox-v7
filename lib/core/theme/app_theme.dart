import 'package:flutter/material.dart';

import 'app_button_themes.dart';
import 'app_chip_theme.dart';
import 'app_interaction_states.dart';
import 'app_overlay_themes.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_stroke.dart';
import 'app_typography.dart';

/// Material 3 themes for the app.
///
/// Only components something actually renders are themed: AppBar, Card,
/// FilledButton, OutlinedButton, TextField and SnackBar from UC-05, plus
/// IconButton, ListTile, Dialog and BottomSheet added in M4.8 when the Mx
/// shared components gave them callers.
///
/// Chip and FloatingActionButton joined them in M4.12: the deck list's filter and
/// sort pills render a `ChoiceChip` through `MxPillButton`, and its create action
/// renders a FAB. Until then both would have been decisions made without a screen
/// to check them against — which is the rule this list follows, not an oversight
/// that was finally corrected.
ThemeData buildLightTheme() => _buildTheme(
  ColorScheme.fromSeed(seedColor: AppColors.seed).copyWith(
    // Every role is declared. `fromSeed` had been generating a neutral-grey
    // surfaceContainer ladder, a pink `tertiary` and a second red for `error` —
    // none visible yet only because the MVP has no Dialog, BottomSheet,
    // NavigationBar, Menu or Chip. See AppColors for the audit.
    primary: AppColors.primaryLight,
    onPrimary: AppColors.onPrimaryLight,
    primaryContainer: AppColors.primaryContainerLight,
    onPrimaryContainer: AppColors.onPrimaryContainerLight,
    secondary: AppColors.secondaryLight,
    onSecondary: AppColors.onSecondaryLight,
    secondaryContainer: AppColors.secondaryContainerLight,
    onSecondaryContainer: AppColors.onSecondaryContainerLight,
    tertiary: AppColors.tertiaryLight,
    onTertiary: AppColors.onTertiaryLight,
    tertiaryContainer: AppColors.tertiaryContainerLight,
    onTertiaryContainer: AppColors.onTertiaryContainerLight,
    // `error` is `danger`, not a second red system.
    error: AppColors.dangerLight,
    onError: AppColors.onErrorLight,
    errorContainer: AppColors.errorContainerLight,
    onErrorContainer: AppColors.onErrorContainerLight,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    onSurfaceVariant: AppColors.textSecondaryLight,
    surfaceDim: AppColors.surfaceDimLight,
    surfaceBright: AppColors.surfaceBrightLight,
    surfaceContainerLowest: AppColors.surfaceContainerLowestLight,
    surfaceContainerLow: AppColors.surfaceContainerLowLight,
    surfaceContainer: AppColors.surfaceContainerLight,
    surfaceContainerHigh: AppColors.surfaceContainerHighLight,
    surfaceContainerHighest: AppColors.surfaceContainerHighestLight,
    outline: AppColors.borderSubtleLight,
    outlineVariant: AppColors.borderSubtleLight,
    inverseSurface: AppColors.inverseSurfaceLight,
    onInverseSurface: AppColors.onInverseSurfaceLight,
    inversePrimary: AppColors.inversePrimaryLight,
    surfaceTint: AppColors.primaryLight,
    // The M3 `*Fixed` family: brightness-independent by definition, so both
    // themes get the same light-container values. No Material component reads
    // them today — which is exactly the argument that left a PINK `tertiary`
    // undetected until an audit went looking. `fromSeed` still generates
    // `tertiaryFixed` at hue 329.
    primaryFixed: AppColors.primaryContainerLight,
    primaryFixedDim: AppColors.primaryContainerLight,
    onPrimaryFixed: AppColors.onPrimaryContainerLight,
    onPrimaryFixedVariant: AppColors.primaryLight,
    secondaryFixed: AppColors.secondaryContainerLight,
    secondaryFixedDim: AppColors.secondaryContainerLight,
    onSecondaryFixed: AppColors.onSecondaryContainerLight,
    onSecondaryFixedVariant: AppColors.secondaryLight,
    tertiaryFixed: AppColors.tertiaryContainerLight,
    tertiaryFixedDim: AppColors.tertiaryContainerLight,
    onTertiaryFixed: AppColors.onTertiaryContainerLight,
    onTertiaryFixedVariant: AppColors.tertiaryLight,
    shadow: AppColors.shadowLight,
    scrim: AppColors.scrimLight,
  ),
  const AppSemanticColors.light(),
  background: AppColors.backgroundLight,
  actionFill: AppColors.primaryLight,
  actionLabel: AppColors.onPrimaryLight,
  outlineLabel: AppColors.secondaryActionLight,
);

ThemeData buildDarkTheme() => _buildTheme(
  ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.primaryDark,
    onPrimary: AppColors.onPrimaryDark,
    primaryContainer: AppColors.primaryContainerDark,
    onPrimaryContainer: AppColors.onPrimaryContainerDark,
    secondary: AppColors.secondaryDark,
    onSecondary: AppColors.onSecondaryDark,
    secondaryContainer: AppColors.secondaryContainerDark,
    onSecondaryContainer: AppColors.onSecondaryContainerDark,
    tertiary: AppColors.tertiaryDark,
    onTertiary: AppColors.onTertiaryDark,
    tertiaryContainer: AppColors.tertiaryContainerDark,
    onTertiaryContainer: AppColors.onTertiaryContainerDark,
    error: AppColors.dangerDark,
    onError: AppColors.onErrorDark,
    errorContainer: AppColors.errorContainerDark,
    onErrorContainer: AppColors.onErrorContainerDark,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimaryDark,
    onSurfaceVariant: AppColors.textSecondaryDark,
    surfaceDim: AppColors.surfaceDimDark,
    surfaceBright: AppColors.surfaceBrightDark,
    surfaceContainerLowest: AppColors.surfaceContainerLowestDark,
    surfaceContainerLow: AppColors.surfaceContainerLowDark,
    surfaceContainer: AppColors.surfaceContainerDark,
    surfaceContainerHigh: AppColors.surfaceContainerHighDark,
    surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
    outline: AppColors.borderSubtleDark,
    outlineVariant: AppColors.borderSubtleDark,
    inverseSurface: AppColors.inverseSurfaceDark,
    onInverseSurface: AppColors.onInverseSurfaceDark,
    inversePrimary: AppColors.inversePrimaryDark,
    // Not the generated tone-80 lavender: Material paints this over elevated
    // surfaces, and a near-pastel tint there undoes the navy canvas.
    surfaceTint: AppColors.surfaceElevatedDark,
    // The M3 `*Fixed` family: brightness-independent by definition, so both
    // themes get the same light-container values. No Material component reads
    // them today — which is exactly the argument that left a PINK `tertiary`
    // undetected until an audit went looking. `fromSeed` still generates
    // `tertiaryFixed` at hue 329.
    primaryFixed: AppColors.primaryContainerLight,
    primaryFixedDim: AppColors.primaryContainerLight,
    onPrimaryFixed: AppColors.onPrimaryContainerLight,
    onPrimaryFixedVariant: AppColors.primaryLight,
    secondaryFixed: AppColors.secondaryContainerLight,
    secondaryFixedDim: AppColors.secondaryContainerLight,
    onSecondaryFixed: AppColors.onSecondaryContainerLight,
    onSecondaryFixedVariant: AppColors.secondaryLight,
    tertiaryFixed: AppColors.tertiaryContainerLight,
    tertiaryFixedDim: AppColors.tertiaryContainerLight,
    onTertiaryFixed: AppColors.onTertiaryContainerLight,
    onTertiaryFixedVariant: AppColors.tertiaryLight,
    shadow: AppColors.shadowDark,
    scrim: AppColors.scrimDark,
  ),
  const AppSemanticColors.dark(),
  background: AppColors.backgroundDark,
  // Indigo in both modes, so the brand is the same object in light and dark.
  // The colour it does NOT compete with is the review verdict pair: those are
  // the only two saturated fills on a review screen, and `secondaryAction` is
  // kept neutral precisely so nothing else in the row has a hue.
  actionFill: AppColors.primaryDark,
  actionLabel: AppColors.onPrimaryDark,
  outlineLabel: AppColors.secondaryActionDark,
);

ThemeData _buildTheme(
  ColorScheme scheme,
  AppSemanticColors semantic, {
  required Color background,
  required Color actionFill,
  required Color actionLabel,
  required Color outlineLabel,
}) {
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    // Anything that builds its own TextStyle without going through the text
    // theme still lands on the body face rather than the platform default.
    fontFamily: AppTypography.bodyFamily,
  );

  // **Built once, then handed to every slot below.** Component themes took
  // Material's own scale off `base` until M4.12 — a pill label at weight 500
  // where `labelLarge` says 600. See `component_theme_typography_test.dart`.
  final texts = AppTypography.buildTextTheme(base.textTheme);

  return base.copyWith(
    // The page sits a step below the card, so a card reads as a card without
    // needing a shadow to say so.
    scaffoldBackgroundColor: background,
    textTheme: texts,
    extensions: <ThemeExtension<Object?>>[semantic],

    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      // No tint on scroll: during a review the header must stay still, because
      // a colour shift behind the card reads as the card itself changing.
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
    ),

    // The bottom bar sits on the page colour, like the app bar above it, so the
    // chrome reads as one frame rather than three surfaces stacked on the
    // content. M3's default would tint it with `surfaceContainer` and give it
    // elevation, which reintroduces exactly the shifting background the app bar
    // deliberately turned off.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: background,
      indicatorColor: scheme.secondaryContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),

    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: semantic.borderSubtle),
      ),
    ),

    // Pills — `MxPillButton`. Selected borrows the navigation bar's indicator
    // pair, so "this one is active" looks the same whether it is a tab or a
    // filter; unselected is a card sitting on the page, which is the same
    // surface-over-background step every other panel uses.
    //
    // No checkmark: the pill group is always visible in full, so the selected
    // one is legible by contrast alone and the tick would shift the label
    // sideways on every change.
    chipTheme: buildChipTheme(scheme, semantic, texts),

    // The create action. `primary` rather than the M3 default
    // `primaryContainer`: this is the one control on the deck list that starts a
    // flow, and it sits over scrolling content where a low-contrast fill would
    // disappear against a card passing underneath.
    //
    // **A rounded square, not a circle.** `CircleBorder` was Material 2's shape;
    // M3's is a 16dp rounded square, and it is what the design draws. A circle
    // beside a 16-radius card reads as a control from a different system.
    //
    // **Shape only, and the missing shadow is deliberate.** AD-14 makes depth one
    // mechanism — `shadowsFor` — and Material's `elevation` is a second one that
    // is not mode-aware and that no audit rule can see. See F11 and F15 in
    // `docs/reviews/design-parity-checklist.md`, and `MxCard` for the same
    // decision on panels.
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),

    filledButtonTheme: buildFilledButtonTheme(
      scheme,
      semantic,
      actionFill: actionFill,
      actionLabel: actionLabel,
    ),

    outlinedButtonTheme: buildOutlinedButtonTheme(
      scheme,
      semantic,
      outlineLabel: outlineLabel,
    ),

    // Focus changes the border's COLOUR, not its weight. Material's default
    // goes 1px -> 2px on focus, which makes the field jump and nudges anything
    // laid out beside it; keeping the stroke at `AppStroke.input` in every state
    // and moving the hue to `focusRing` is the difference between a field
    // answering and a field shouting.
    inputDecorationTheme: InputDecorationTheme(
      // Outlined, not filled. A fill makes the field a block that competes with
      // the cards around it; the reference defines the field with a stroke alone
      // and lets the page show through, so the field reads as an opening rather
      // than an object, and sits correctly on page or card with no override.
      filled: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: _inputBorder(semantic.borderSubtle),
      enabledBorder: _inputBorder(semantic.borderSubtle),
      focusedBorder: _inputBorder(semantic.focusRing),
      errorBorder: _inputBorder(semantic.danger),
      focusedErrorBorder: _inputBorder(semantic.danger),
      // Solid, per MX-VIS-002 rule R7. Blended here rather than read from
      // `disabledSurface`: this is the *hairline* faded, that is the *ink*.
      disabledBorder: _inputBorder(
        Color.alphaBlend(
          semantic.borderSubtle.withValues(alpha: 0.5),
          scheme.surface,
        ),
      ),
      hintStyle: texts.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
    ),

    // Four component themes added in M4.8, one per shared component that
    // renders through them — a theme for one nobody builds is a decision made
    // without a screen to check it against.
    iconButtonTheme: IconButtonThemeData(
      style:
          IconButton.styleFrom(
            // The 48×48 minimum lives here rather than in `MxIconButton`, so no
            // screen can pass a smaller one — there is no parameter to pass.
            minimumSize: const Size.square(AppSpacing.minimumTouchTarget),
            foregroundColor: scheme.onSurfaceVariant,
            // Named, not left to `defaultStyleOf` where no audit can see it.
            disabledForegroundColor: semantic.onDisabled,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ).copyWith(
            // Hover, press and focus declared. Left null they came from
            // Material, which is neither the kit nor what every other control
            // in this app resolves.
            overlayColor: AppInteractionStates.iconOverlay(scheme),
            // Focus draws a ring, not just the tint: measured off the goldens
            // that tint alone is 1.15:1 against the surface behind it in both
            // modes, where WCAG 1.4.11 asks 3:1 of a focus indicator.
            side: WidgetStateProperty.resolveWith((states) {
              if (!states.contains(WidgetState.focused)) return null;
              return AppInteractionStates.focusRing(scheme);
            }),
          ),
    ),

    progressIndicatorTheme: buildProgressIndicatorTheme(scheme, semantic),
    tooltipTheme: buildTooltipTheme(scheme, texts),
    textSelectionTheme: buildTextSelectionTheme(scheme, semantic),
    dividerTheme: buildDividerTheme(semantic),
    scrollbarTheme: buildScrollbarTheme(scheme),

    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      minVerticalPadding: AppSpacing.sm,
      iconColor: scheme.onSurfaceVariant,
      textColor: scheme.onSurface,
      selectedColor: scheme.primary,
      selectedTileColor: semantic.surfaceMuted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),

    dialogTheme: DialogThemeData(
      barrierColor: modalBarrierColor(scheme),
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      // Zero, for the same reason as the FAB above: a second depth mechanism
      // AD-14 does not admit. See F15.
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: semantic.borderSubtle),
      ),
      titleTextStyle: texts.titleMedium?.copyWith(color: scheme.onSurface),
      contentTextStyle: texts.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      modalBarrierColor: modalBarrierColor(scheme),
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: semantic.borderSubtle,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: texts.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
  );
}

/// Same geometry and the same stroke in every state — only the colour speaks.
OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(AppRadius.md),
  borderSide: BorderSide(color: color, width: AppStroke.input),
);
