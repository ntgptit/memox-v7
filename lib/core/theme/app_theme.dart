import 'package:flutter/material.dart';

import 'app_button_themes.dart';
import 'app_chip_theme.dart';
import 'app_icon_size.dart';
import 'app_input_theme.dart';
import 'app_interaction_states.dart';
import 'app_overlay_themes.dart';
import 'app_colors.dart';
import 'app_elevation.dart';
import 'app_material_roles.dart';
import 'app_navigation_bar_theme.dart';
import 'app_radio_theme.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';
import 'app_typography.dart';

/// Material 3 themes for the app.
///
/// Only components something actually renders are themed: AppBar, Card,
/// FilledButton, OutlinedButton, TextField and SnackBar from UC-05, plus
/// IconButton, ListTile, Dialog and BottomSheet added in M4.8 when the Mx
/// shared components gave them callers.
///
/// Chip joined in M4.12 — the deck list's filter and sort pills render a
/// `ChoiceChip` through `MxPillButton`. The FloatingActionButton theme left
/// with the FAB itself when M4.10ag moved the create action into the app bar;
/// TextButton and Radio joined when `MxTextButton` and the deck form's
/// scheduler picker gave them callers. A theme for a component nobody renders
/// is a decision made without a screen to check it against — which is the rule
/// this list follows, in both directions.
///
/// **Built once, and the memoisation is load-bearing rather than an
/// optimisation.** `ThemeData.==` walks every component theme, and the ones
/// here hold `WidgetStateProperty.resolveWith` closures — no value equality, so
/// two themes off identical tokens are never `==`. `MemoxApp` calls these from
/// `build()`, which runs on the settings stream; every such rebuild would hand
/// `MaterialApp` an unequal theme, and `Theme.updateShouldNotify` is exactly
/// `data != oldWidget.data`. One instance makes the comparison `identical` and
/// the whole-tree invalidation stop. Sharing it is safe — `ThemeData` and both
/// extensions are immutable — and `app_theme_identity_test.dart` pins it.
ThemeData buildLightTheme() => _lightTheme;

ThemeData buildDarkTheme() => _darkTheme;

final ThemeData _lightTheme = _buildTheme(
  // The constructor, not `fromSeed(...).copyWith(...)`. Every role the app
  // ships is a hand-tuned constant, and `fromSeed` had been generating a
  // parallel set nobody rendered — a neutral-grey surfaceContainer ladder, a
  // pink `tertiary`, a second red for `error` — which read as "there is a
  // tonal palette" when there is none. What is not passed falls back to the
  // constructor's own derivations (the `*Fixed` family lands on its base
  // role); nothing reads those, and `app_theme_test.dart` is what notices if
  // something starts to.
  const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primaryLight,
    onPrimary: AppColors.onPrimaryLight,
    primaryContainer: AppMaterialRoles.primaryContainerLight,
    onPrimaryContainer: AppMaterialRoles.onPrimaryContainerLight,
    secondary: AppMaterialRoles.secondaryLight,
    onSecondary: AppMaterialRoles.onSecondaryLight,
    secondaryContainer: AppMaterialRoles.secondaryContainerLight,
    onSecondaryContainer: AppMaterialRoles.onSecondaryContainerLight,
    tertiary: AppMaterialRoles.tertiaryLight,
    onTertiary: AppMaterialRoles.onTertiaryLight,
    tertiaryContainer: AppMaterialRoles.tertiaryContainerLight,
    onTertiaryContainer: AppMaterialRoles.onTertiaryContainerLight,
    // `error` is `danger`, not a second red system.
    error: AppColors.dangerLight,
    onError: AppMaterialRoles.onErrorLight,
    errorContainer: AppMaterialRoles.errorContainerLight,
    onErrorContainer: AppMaterialRoles.onErrorContainerLight,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    onSurfaceVariant: AppColors.textSecondaryLight,
    surfaceDim: AppMaterialRoles.surfaceDimLight,
    surfaceBright: AppMaterialRoles.surfaceBrightLight,
    surfaceContainerLowest: AppMaterialRoles.surfaceContainerLowestLight,
    surfaceContainerLow: AppMaterialRoles.surfaceContainerLowLight,
    surfaceContainer: AppMaterialRoles.surfaceContainerLight,
    surfaceContainerHigh: AppMaterialRoles.surfaceContainerHighLight,
    surfaceContainerHighest: AppMaterialRoles.surfaceContainerHighestLight,
    // **The M3 pair, at last as a pair.** `outline` is the stroke the spec
    // asks to identify a component's boundary — the 3:1 of WCAG 1.4.11 — and
    // `outlineVariant` is the decorative hairline. Both used to be
    // `borderSubtle`, which handed any component that trusts `scheme.outline`
    // a 1.45:1 edge. The app's own widgets read the semantic tokens directly,
    // so this re-mapping changes what an *untended* widget degrades to, not
    // what the app draws.
    outline: AppColors.borderControlLight,
    outlineVariant: AppColors.borderSubtleLight,
    inverseSurface: AppMaterialRoles.inverseSurfaceLight,
    onInverseSurface: AppMaterialRoles.onInverseSurfaceLight,
    inversePrimary: AppMaterialRoles.inversePrimaryLight,
    surfaceTint: AppColors.primaryLight,
    shadow: AppColors.shadowLight,
    scrim: AppColors.scrimLight,
  ),
  const AppSemanticColors.light(),
  background: AppColors.backgroundLight,
  actionFill: AppColors.primaryLight,
  actionLabel: AppColors.onPrimaryLight,
  outlineLabel: AppColors.secondaryActionLight,
);

final ThemeData _darkTheme = _buildTheme(
  const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryDark,
    onPrimary: AppColors.onPrimaryDark,
    primaryContainer: AppMaterialRoles.primaryContainerDark,
    onPrimaryContainer: AppMaterialRoles.onPrimaryContainerDark,
    secondary: AppMaterialRoles.secondaryDark,
    onSecondary: AppMaterialRoles.onSecondaryDark,
    secondaryContainer: AppMaterialRoles.secondaryContainerDark,
    onSecondaryContainer: AppMaterialRoles.onSecondaryContainerDark,
    tertiary: AppMaterialRoles.tertiaryDark,
    onTertiary: AppMaterialRoles.onTertiaryDark,
    tertiaryContainer: AppMaterialRoles.tertiaryContainerDark,
    onTertiaryContainer: AppMaterialRoles.onTertiaryContainerDark,
    error: AppColors.dangerDark,
    onError: AppMaterialRoles.onErrorDark,
    errorContainer: AppMaterialRoles.errorContainerDark,
    onErrorContainer: AppMaterialRoles.onErrorContainerDark,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimaryDark,
    onSurfaceVariant: AppColors.textSecondaryDark,
    surfaceDim: AppMaterialRoles.surfaceDimDark,
    surfaceBright: AppMaterialRoles.surfaceBrightDark,
    surfaceContainerLowest: AppMaterialRoles.surfaceContainerLowestDark,
    surfaceContainerLow: AppMaterialRoles.surfaceContainerLowDark,
    surfaceContainer: AppMaterialRoles.surfaceContainerDark,
    surfaceContainerHigh: AppMaterialRoles.surfaceContainerHighDark,
    surfaceContainerHighest: AppMaterialRoles.surfaceContainerHighestDark,
    // The same pair as light — see the note there.
    outline: AppColors.borderControlDark,
    outlineVariant: AppColors.borderSubtleDark,
    inverseSurface: AppMaterialRoles.inverseSurfaceDark,
    onInverseSurface: AppMaterialRoles.onInverseSurfaceDark,
    inversePrimary: AppMaterialRoles.inversePrimaryDark,
    // `primary`, the canonical M3 mapping, and the earlier deviation to
    // `surfaceElevatedDark` is retired: every themed component sets
    // `surfaceTintColor: transparent`, so what this role must be is *true*
    // for the one reader it can still have — an untended elevated widget —
    // rather than a value chosen to soften a tint the app already suppresses.
    surfaceTint: AppColors.primaryDark,
    shadow: AppColors.shadowDark,
    scrim: AppColors.scrimDark,
  ),
  const AppSemanticColors.dark(),
  background: AppColors.backgroundDark,
  // Indigo in both modes, so the brand is the same object in light and dark.
  // The colour it does NOT compete with is the study verdict pair: those are
  // the only two saturated fills on a study screen, and `secondaryAction` is
  // kept neutral precisely so nothing else in the row has a hue.
  actionFill: AppColors.primaryDark,
  actionLabel: AppColors.onPrimaryDark,
  outlineLabel: AppColors.secondaryActionDark,
);

/// The FAB's Material elevation, per brightness — the one component that keeps
/// a dp value instead of `elevation: 0` + `shadowsFor`, because
/// `FloatingActionButtonThemeData` has no slot for a hand-painted shadow.
double _fabElevation(ColorScheme scheme) => scheme.brightness == Brightness.dark
    ? AppElevation.none
    : AppElevation.overlay;

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
    // Pinned, not platform-adaptive. Android is the release target, but the
    // web build is the E2E channel (AD-04) — and Flutter's platform defaults
    // hand a desktop browser `compact` density and `shrinkWrap` tap targets,
    // so every Playwright measurement would be taken on geometry Android never
    // renders. `standard` and `padded` are Android's own values, declared so
    // the two channels cannot drift apart.
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
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
    extensions: <ThemeExtension<Object?>>[semantic, AppTextStyles.from(texts)],

    // The framework fall-through, seeded. Anything not themed below — a bare
    // `InkWell`, a third-party widget — resolves its washes from these four,
    // and Material's own values are hardcoded black-and-white with no seed in
    // them, identical in light and dark (see `AppStateOpacity`'s file
    // comment). The hues and alphas are the ones `AppInteractionStates`
    // resolves, so an untended control degrades to the house washes rather
    // than to a foreign system. Translucent deliberately: these paint over
    // grounds this file cannot know, which is R7's overlay exemption.
    hoverColor: scheme.onSurfaceVariant.withValues(
      alpha: AppStateOpacity.hoverRow,
    ),
    focusColor: scheme.primary.withValues(alpha: AppStateOpacity.focus),
    highlightColor: scheme.primary.withValues(alpha: AppStateOpacity.pressed),
    splashColor: scheme.primary.withValues(alpha: AppStateOpacity.pressed),

    // A bare `Icon` outside every themed component. Material's fallback is a
    // hardcoded black87/white pair, not even `onSurface`; declaring the
    // secondary ink at the standard glyph size means an icon nobody styled
    // degrades on-brand — the same colour every quiet glyph in the app wears.
    iconTheme: IconThemeData(
      color: scheme.onSurfaceVariant,
      size: AppIconSize.md,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      // No tint on scroll: during a study session the header must stay still, because
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
    // **The brand pair, stated.** Material 3's default is the
    // `primaryContainer` tonal pair, which puts the screen's one create action
    // in the same clothes as the navigation bar's active tab. The owner's
    // mockup draws it as the brand fill (owner review, 2026-08-20), and the
    // pair carries its own contrast guarantee.
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      // Zero in dark, matching `shadowsFor`: the dark page is at the bottom of
      // the lightness scale, so a shadow there is paint nobody can see — and
      // until this matched, the FAB was the one object in dark carrying a
      // Material shadow while every other surface had measurably opted out.
      elevation: _fabElevation(scheme),
      focusElevation: _fabElevation(scheme),
      hoverElevation: _fabElevation(scheme),
      highlightElevation: _fabElevation(scheme),
    ),
    navigationBarTheme: buildNavigationBarTheme(scheme, texts, background),

    // The safety net for a bare or third-party `Card` — no app widget renders
    // one. `MxCard` is the canonical card and paints itself, because its
    // focus-ring border swap and `shadowsFor` depth have no `CardThemeData`
    // slot; this keeps an untended `Card` on the same surface, radius and
    // hairline instead of Material's elevated default.
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

    textButtonTheme: buildTextButtonTheme(scheme, semantic, texts),

    inputDecorationTheme: buildInputDecorationTheme(scheme, semantic, texts),

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
              return AppInteractionStates.focusRing(semantic);
            }),
          ),
    ),

    progressIndicatorTheme: buildProgressIndicatorTheme(scheme, semantic),
    tooltipTheme: buildTooltipTheme(scheme, texts),
    textSelectionTheme: buildTextSelectionTheme(scheme, semantic),
    dividerTheme: buildDividerTheme(semantic),
    scrollbarTheme: buildScrollbarTheme(scheme),
    radioTheme: buildRadioTheme(scheme, semantic),

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
