import 'package:flutter/material.dart';

import 'app_button_themes.dart';
import 'app_chip_theme.dart';
import 'app_icon_size.dart';
import 'app_input_theme.dart';
import 'app_interaction_states.dart';
import 'app_overlay_themes.dart';
import 'app_planned_themes.dart';
import 'app_colors.dart';
import 'app_elevation.dart';
import 'app_high_contrast.dart';
import 'app_material_roles.dart';
import 'app_navigation_bar_theme.dart';
import 'app_radio_theme.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';
import 'app_toggle_themes.dart';
import 'app_typography.dart';
import 'app_surface_colors.dart';
import 'app_border_colors.dart';

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
/// optimisation.** `ThemeData.==` compares every component theme, and a
/// component theme here holds `WidgetStateProperty.resolveWith((states) {...})`
/// — a fresh closure on every call, with no value equality. So two themes built
/// from identical tokens are never `==`, and with
/// `themeAnimationDuration: Duration.zero` (`app.dart`) `MaterialApp` mounts a
/// plain `Theme`, whose `updateShouldNotify` is exactly `data != oldWidget.data`.
///
/// `MemoxApp` calls these from a `build()` that would therefore invalidate
/// **every** `Theme.of(context)` dependent in the tree each time it ran — and
/// it runs on the settings stream, so at minimum on the cold-start loading→data
/// emission and on every theme or language change. Returning one instance makes
/// that comparison `identical` and the notification stop.
///
/// One instance is safe to share: `ThemeData` and both extensions are
/// immutable. Tests get the same object, which is what they should be asserting
/// on anyway. `app_theme_identity_test.dart` pins both halves.
ThemeData buildLightTheme() => _lightTheme;

ThemeData buildDarkTheme() => _darkTheme;

/// The two themes `MaterialApp` reaches for when the platform reports
/// `MediaQuery.highContrast` — Android's "High contrast text" and the
/// equivalent switch on every other platform.
///
/// **Both slots were null until M99.48, which is why the setting did nothing.**
/// What changes is borders and disabled ink and nothing else; the reasoning and
/// every measurement are in `app_high_contrast.dart`. Memoised for the reason
/// the other two are — see this file's header.
ThemeData buildHighContrastLightTheme() => _highContrastLightTheme;

ThemeData buildHighContrastDarkTheme() => _highContrastDarkTheme;

// The constructor, not `fromSeed(...).copyWith(...)`. Every role the app
// ships is a hand-tuned constant, and `fromSeed` had been generating a
// parallel set nobody rendered — a neutral-grey surfaceContainer ladder, a
// pink `tertiary`, a second red for `error` — which read as "there is a
// tonal palette" when there is none.
//
// **Exactly the 45 Material 3 colour roles are passed — no fewer, and
// nothing that is not one.** 26 standard roles (the `primary`, `secondary`,
// `tertiary` and `error` quartets; `surface`, `onSurface`,
// `onSurfaceVariant`; `outline` and `outlineVariant`; the `inverse*` trio;
// `shadow` and `scrim`) and 19 add-ons (`surfaceDim`, `surfaceBright`, the
// five `surfaceContainer*` rungs, and the twelve `*Fixed`). The `*Fixed`
// twelve arrived last (M99.47): until then each fell through the
// constructor's own fallback to its *base* role (`_primaryFixed ?? primary`)
// — a fill-level tone in a container-level slot, and a different value in
// each brightness for a role the spec defines as brightness-independent.
//
// The constructor accepts a few more names than that — three deprecated
// roles and one tint mechanism — and none is passed, read, dumped or
// swatched anywhere in this repository. The guard locks the names to the
// list above by allowlist rather than by naming what is out:
// `memox_v7.design_system.color_scheme_arguments_are_m3_roles` for what a
// `ColorScheme(` or a scheme's `copyWith(` may be handed, and
// `memox_v7.design_system.color_scheme_reads_are_m3_roles` for what may be
// read off one anywhere under `lib/` (M100.17).
const ColorScheme _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.primaryLight,
  onPrimary: AppColors.onPrimaryLight,
  primaryContainer: AppMaterialRoles.primaryContainerLight,
  onPrimaryContainer: AppMaterialRoles.onPrimaryContainerLight,
  // The `*Fixed` family carries no brightness suffix because the role is
  // defined as the same colour in both themes; see `AppMaterialRoles`.
  primaryFixed: AppMaterialRoles.primaryFixed,
  primaryFixedDim: AppMaterialRoles.primaryFixedDim,
  onPrimaryFixed: AppMaterialRoles.onPrimaryFixed,
  onPrimaryFixedVariant: AppMaterialRoles.onPrimaryFixedVariant,
  secondary: AppMaterialRoles.secondaryLight,
  onSecondary: AppMaterialRoles.onSecondaryLight,
  secondaryContainer: AppMaterialRoles.secondaryContainerLight,
  onSecondaryContainer: AppMaterialRoles.onSecondaryContainerLight,
  secondaryFixed: AppMaterialRoles.secondaryFixed,
  secondaryFixedDim: AppMaterialRoles.secondaryFixedDim,
  onSecondaryFixed: AppMaterialRoles.onSecondaryFixed,
  onSecondaryFixedVariant: AppMaterialRoles.onSecondaryFixedVariant,
  tertiary: AppMaterialRoles.tertiaryLight,
  onTertiary: AppMaterialRoles.onTertiaryLight,
  tertiaryContainer: AppMaterialRoles.tertiaryContainerLight,
  onTertiaryContainer: AppMaterialRoles.onTertiaryContainerLight,
  tertiaryFixed: AppMaterialRoles.tertiaryFixed,
  tertiaryFixedDim: AppMaterialRoles.tertiaryFixedDim,
  onTertiaryFixed: AppMaterialRoles.onTertiaryFixed,
  onTertiaryFixedVariant: AppMaterialRoles.onTertiaryFixedVariant,
  // `error` is `danger`, not a second red system.
  error: AppColors.dangerLight,
  onError: AppMaterialRoles.onErrorLight,
  errorContainer: AppMaterialRoles.errorContainerLight,
  onErrorContainer: AppMaterialRoles.onErrorContainerLight,
  surface: AppSurfaceColors.surfaceLight,
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
  outline: AppBorderColors.borderControlLight,
  outlineVariant: AppBorderColors.borderSubtleLight,
  inverseSurface: AppMaterialRoles.inverseSurfaceLight,
  onInverseSurface: AppMaterialRoles.onInverseSurfaceLight,
  inversePrimary: AppMaterialRoles.inversePrimaryLight,
  shadow: AppColors.shadowLight,
  scrim: AppColors.scrimLight,
);

const ColorScheme _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: AppColors.primaryDark,
  onPrimary: AppColors.onPrimaryDark,
  primaryContainer: AppMaterialRoles.primaryContainerDark,
  onPrimaryContainer: AppMaterialRoles.onPrimaryContainerDark,
  // The `*Fixed` family carries no brightness suffix because the role is
  // defined as the same colour in both themes; see `AppMaterialRoles`.
  primaryFixed: AppMaterialRoles.primaryFixed,
  primaryFixedDim: AppMaterialRoles.primaryFixedDim,
  onPrimaryFixed: AppMaterialRoles.onPrimaryFixed,
  onPrimaryFixedVariant: AppMaterialRoles.onPrimaryFixedVariant,
  secondary: AppMaterialRoles.secondaryDark,
  onSecondary: AppMaterialRoles.onSecondaryDark,
  secondaryContainer: AppMaterialRoles.secondaryContainerDark,
  onSecondaryContainer: AppMaterialRoles.onSecondaryContainerDark,
  secondaryFixed: AppMaterialRoles.secondaryFixed,
  secondaryFixedDim: AppMaterialRoles.secondaryFixedDim,
  onSecondaryFixed: AppMaterialRoles.onSecondaryFixed,
  onSecondaryFixedVariant: AppMaterialRoles.onSecondaryFixedVariant,
  tertiary: AppMaterialRoles.tertiaryDark,
  onTertiary: AppMaterialRoles.onTertiaryDark,
  tertiaryContainer: AppMaterialRoles.tertiaryContainerDark,
  onTertiaryContainer: AppMaterialRoles.onTertiaryContainerDark,
  tertiaryFixed: AppMaterialRoles.tertiaryFixed,
  tertiaryFixedDim: AppMaterialRoles.tertiaryFixedDim,
  onTertiaryFixed: AppMaterialRoles.onTertiaryFixed,
  onTertiaryFixedVariant: AppMaterialRoles.onTertiaryFixedVariant,
  error: AppColors.dangerDark,
  onError: AppMaterialRoles.onErrorDark,
  errorContainer: AppMaterialRoles.errorContainerDark,
  onErrorContainer: AppMaterialRoles.onErrorContainerDark,
  surface: AppSurfaceColors.surfaceDark,
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
  outline: AppBorderColors.borderControlDark,
  outlineVariant: AppBorderColors.borderSubtleDark,
  inverseSurface: AppMaterialRoles.inverseSurfaceDark,
  onInverseSurface: AppMaterialRoles.onInverseSurfaceDark,
  inversePrimary: AppMaterialRoles.inversePrimaryDark,
  shadow: AppColors.shadowDark,
  scrim: AppColors.scrimDark,
);

/// The light theme, given the palette it should read.
///
/// This used to also relay `actionFill` / `actionLabel` / `outlineLabel`
/// constants alongside the scheme that already carries those meanings — one
/// meaning, two sources, and the high-contrast themes were exactly where the
/// two would have parted (they transform the scheme; the relayed constants
/// would have stayed put). The builders read the scheme now; only the page
/// ground remains an argument, because the scheme genuinely has no role for
/// it.
ThemeData _light(ColorScheme scheme, AppSemanticColors semantic) =>
    _buildTheme(scheme, semantic, background: AppSurfaceColors.backgroundLight);

/// The dark theme. See [_light].
///
/// The brand stays indigo in both modes — `scheme.primary` carries it — so the
/// button pair is the same object in light and dark. The colour it competes
/// with is the study verdict pair, the only two saturated *fills* on a study
/// screen. `AppColors.secondaryAction*` used to keep the outlined button out of
/// that contest by not being the brand at all; M100.22 retired it, because a
/// second name for `primary` is not a way to answer a hierarchy question — the
/// outlined button is a hairline and a label against two filled verdicts, and
/// the weight difference is what separates them.
ThemeData _dark(ColorScheme scheme, AppSemanticColors semantic) =>
    _buildTheme(scheme, semantic, background: AppSurfaceColors.backgroundDark);

final ThemeData _lightTheme = _light(
  _lightScheme,
  const AppSemanticColors.light(),
);

final ThemeData _darkTheme = _dark(_darkScheme, const AppSemanticColors.dark());

final ThemeData _highContrastLightTheme = _light(
  highContrastScheme(_lightScheme),
  highContrastSemantics(const AppSemanticColors.light(), _lightScheme),
);

final ThemeData _highContrastDarkTheme = _dark(
  highContrastScheme(_darkScheme),
  highContrastSemantics(const AppSemanticColors.dark(), _darkScheme),
);

/// Material elevation for the overlays that keep a dp value instead of
/// `elevation: 0` + `shadowsFor` — the FAB and the SnackBar, whose theme slots
/// have nowhere to put a hand-painted shadow.
///
/// Zero in dark, matching `shadowsFor`: the dark page is at the bottom of the
/// lightness scale, so a shadow there is paint nobody can see.
double _overlayElevation(ColorScheme scheme) =>
    scheme.brightness == Brightness.dark
    ? AppElevation.none
    : AppElevation.overlay;

/// `background` stays a parameter where the button pairs did not: the page
/// ground is deliberately not `scheme.surface` (surface is the card sitting on
/// it), so there genuinely is no second source for it inside the scheme.
ThemeData _buildTheme(
  ColorScheme scheme,
  AppSemanticColors semantic, {
  required Color background,
}) {
  final base = ThemeData(
    // The SDK's current default, restated because it is a dependency and not a
    // preference: the FAB state washes, the button overlays and the planned
    // themes all correct *M3's* defaults specifically, and an SDK that ever
    // flipped this flag would swap the baseline under every one of those
    // corrections without a line here changing.
    useMaterial3: true,
    colorScheme: scheme,
    // Pinned, not platform-adaptive. Android is the release target, but the
    // web build is the E2E channel (AD-04) — and Flutter's platform defaults
    // hand a desktop browser `compact` density and `shrinkWrap` tap targets,
    // so every Playwright measurement would be taken on geometry Android never
    // renders. `standard` and `padded` are Android's own values, declared so
    // the two channels cannot drift apart.
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    // **The same argument, finished.** The two lines above pin density and tap
    // target so the web E2E channel measures Android's geometry — and left
    // `platform` itself reading `defaultTargetPlatform`, which is the value
    // both of them exist to stop trusting. Everything Material resolves per
    // platform therefore still forked at the browser's OS: the page transition
    // most visibly (Android draws `PredictiveBackPageTransitionsBuilder`,
    // Linux and Windows `ZoomPageTransitionsBuilder`, macOS the Cupertino
    // slide), and with it scroll physics and the text-selection controls.
    //
    // Android is the release target (AD-04) and the web build is the channel
    // that has to agree with it, so the platform is declared rather than
    // detected. A Playwright run now exercises the transition a phone runs.
    //
    // `pageTransitionsTheme` is left at its default *given* that platform:
    // pinning the platform is what makes the default correct, and naming a
    // builder as well would be a second place to keep in step with the SDK's
    // own Android answer.
    platform: TargetPlatform.android,
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

    // **Two more of the same kind, for the one widget family that has no
    // component theme at all.** `DropdownButton` is a Material 2 survivor —
    // `ThemeData` has no slot for it, only `dropdownMenuTheme` for the
    // unrelated `DropdownMenu` — so it resolves straight from these top-level
    // colours, and the card importer builds two of them.
    //
    // `canvasColor` is the menu it opens; without it the menu takes
    // `ThemeData`'s own default rather than this app's card surface.
    // `disabledColor` is worse: Material's fallback is a hardcoded
    // `black38`/`white38` with no seed in it, which is the same class of
    // unseeded default `AppStateOpacity`'s file comment was opened for.
    //
    // `theme_coverage_test.dart` cannot reach this pair — its whole mechanism
    // is a widget-to-slot map, and there is no slot — so the gap is closed
    // here and named in that file's blind-spot list.
    canvasColor: scheme.surface,
    disabledColor: semantic.onDisabled,

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
      // The house corner, stated here rather than at the one call site it
      // used to live on (deck list): a FAB shape is component grammar, and
      // M3's default is the 16dp large-component squircle this app does not
      // use anywhere else.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      // **The state washes move with the pair, or they describe the old one.**
      // M3's defaults are not derived from the effective foreground — the SDK
      // hardcodes `onPrimaryContainer` at 8/10/10% — so overriding the resting
      // pair above and leaving these null meant hover, focus and press painted
      // another system's ink over this system's fill (theme-composition
      // review, 2026-08). The rule Chip and the buttons already follow: change
      // a component's resting pair, and every state default it owns is yours
      // to restate.
      hoverColor: scheme.onPrimary.withValues(
        alpha: AppStateOpacity.hoverControl,
      ),
      focusColor: scheme.onPrimary.withValues(alpha: AppStateOpacity.focus),
      splashColor: scheme.onPrimary.withValues(alpha: AppStateOpacity.pressed),
      // Until the elevation matched `shadowsFor`, the FAB was the one object
      // in dark carrying a Material shadow while every other surface had
      // measurably opted out.
      elevation: _overlayElevation(scheme),
      focusElevation: _overlayElevation(scheme),
      hoverElevation: _overlayElevation(scheme),
      highlightElevation: _overlayElevation(scheme),
    ),
    navigationBarTheme: buildNavigationBarTheme(scheme, texts),

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
        side: BorderSide(color: scheme.outlineVariant),
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

    filledButtonTheme: buildFilledButtonTheme(scheme, semantic),

    outlinedButtonTheme: buildOutlinedButtonTheme(scheme, semantic),

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
              return AppInteractionStates.focusRing(scheme);
            }),
          ),
    ),

    progressIndicatorTheme: buildProgressIndicatorTheme(scheme),
    tooltipTheme: buildTooltipTheme(scheme, texts),
    textSelectionTheme: buildTextSelectionTheme(scheme),
    dividerTheme: buildDividerTheme(scheme),
    scrollbarTheme: buildScrollbarTheme(scheme),
    radioTheme: buildRadioTheme(scheme, semantic),
    switchTheme: buildSwitchTheme(scheme, semantic),
    checkboxTheme: buildCheckboxTheme(scheme, semantic),

    // The reminder screen's `showTimePicker`. Its dialog does NOT read
    // `dialogTheme` — see `buildTimePickerTheme` — so without this entry it is
    // the one surface in the app carrying Material's elevation and corner.
    timePickerTheme: buildTimePickerTheme(scheme, texts),
    popupMenuTheme: buildPopupMenuTheme(scheme, semantic, texts),

    // Four components nothing renders yet. They are here rather than left to
    // Material because each one only restates a decision this app has already
    // made and measured — the admission test, and the ones it turned away, are
    // in `app_planned_themes.dart`. `theme_coverage_test.dart` is what stops
    // the list growing on a hunch.
    datePickerTheme: buildDatePickerTheme(scheme, semantic, texts),
    segmentedButtonTheme: buildSegmentedButtonTheme(scheme, semantic),
    sliderTheme: buildSliderTheme(scheme, semantic, texts),
    tabBarTheme: buildTabBarTheme(scheme, texts),

    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      minVerticalPadding: AppSpacing.sm,
      iconColor: scheme.onSurfaceVariant,
      textColor: scheme.onSurface,
      // **`primary`, and the ground is what used to make that hard.** A
      // selected row lands on `surfaceMuted`, not the page, and the old dark
      // fill tone measured 2.45:1 there — under WCAG 1.4.11's 3:1 for a state
      // and far under the 4.5:1 its label needs, which is why a second token
      // stood here until M100.19. Tone 80 clears both grounds outright.
      //
      // Not the `secondaryContainer` pair NavigationBar and the chips take,
      // though that would also pass: a row is a wide target, and a tinted fill
      // stretched across a list reads as a button. The muted tile with an
      // accented label keeps the grammar — brand tint means selected — at a
      // weight a row can carry. `ListTile` has no M3 selected-fill default to
      // depart from; `selectedTileColor` is null in Material and the choice is
      // the app's to make.
      selectedColor: scheme.primary,
      selectedTileColor: semantic.surfaceMuted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),

    dialogTheme: DialogThemeData(
      barrierColor: modalBarrierColor(scheme),
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      // Zero, for the same reason as the FAB above: a second depth mechanism
      // AD-14 does not admit. See F15.
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      titleTextStyle: texts.titleMedium?.copyWith(color: scheme.onSurface),
      contentTextStyle: texts.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      // **`actionsPadding` deliberately stays unset here** — it moved to
      // `MxDialogMetrics` while this was in flight (#348). The footer's width
      // has to be *computed* from that inset, so the dialog states it on the
      // widget; a theme entry saying the same 24 would be a second answer that
      // all three dialogs override, and the one that could silently drift out
      // of step with the arithmetic that reads it.
    ),

    bottomSheetTheme: BottomSheetThemeData(
      modalBarrierColor: modalBarrierColor(scheme),
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: true,
      // **The handle is a button, not a decoration, and the SDK is explicit
      // about it:** `_DragHandle` wraps itself in `Semantics(button: true,
      // onTap: …)` with the dismiss label and pads itself to
      // `kMinInteractiveDimension`. So WCAG 1.4.11's 3:1 applies to it, and
      // `borderSubtle` — the decorative hairline, `outlineVariant` — measured
      // **1.45:1** in light and **2.04:1** in dark. It is the only thing on the
      // sheet that says the sheet can be dragged or dismissed.
      //
      // **`borderControl` rather than `onSurfaceVariant`, and that was decided
      // by looking.** Material's default for this slot is `onSurfaceVariant`,
      // which here measures 6.45 and 7.29 — it clears the floor twice over and
      // renders as a bar heavy enough to take the eye *before* the sheet's own
      // heading. A sheet's first job is to say what it is. `borderControl`
      // reads as an affordance at 3.19 and 3.00 without competing, and it is
      // the token this app already means by "interactive control".
      dragHandleColor: WidgetStateColor.resolveWith((states) {
        // **Two states, because two is all the SDK ever sets here** — it adds
        // `hovered` from its own `MouseRegion` and `dragged` while the sheet is
        // actually moving. No focus and no pressed: the handle has semantics
        // but no `Focus`, so it is not in the traversal.
        //
        // `dragged` is the one that matters on the release platform. Hover does
        // not exist on a phone; the grab does, and until now it looked exactly
        // like the rest.
        //
        // **The resting value is `onSurfaceVariant`, which is
        // `_BottomSheetDefaultsM3.dragHandleColor`.** It read `outline` until
        // M100.22, with `onSurfaceVariant` held back as the grabbed state —
        // which is M3's resting answer used as an emphasis, so the handle sat
        // one step quieter than Material draws it and the emphasis only
        // restored the default. Resting is M3's now and the grab goes up to
        // `onSurface`: the same ladder, one rung higher, no new token and no
        // paint-time alpha (AD-14 §1 wants a known ground pre-composed).
        if (states.contains(WidgetState.dragged) ||
            states.contains(WidgetState.hovered)) {
          return scheme.onSurface;
        }

        return scheme.onSurfaceVariant;
      }),
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
      // The SDK's own default, restated so the action's colour is a decision
      // on record rather than a silence that resolves to one.
      actionTextColor: scheme.inversePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      // The last overlay that let Material decide its depth: Dialog,
      // BottomSheet, PopupMenu and the FAB all state theirs, and this slot's
      // silence resolved to the SDK's 6.0 — in dark too, where every other
      // surface has measurably opted out of shadows. Same brightness split as
      // the FAB, for the same reason (theme-composition review, 2026-08).
      elevation: _overlayElevation(scheme),
    ),
  );
}
