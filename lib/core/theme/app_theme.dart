import 'package:flutter/material.dart';

import 'components/actions/app_button_themes.dart';
import 'components/actions/app_fab_theme.dart';
import 'components/actions/app_icon_button_theme.dart';
import 'components/content/app_divider_theme.dart';
import 'components/content/app_list_tile_theme.dart';
import 'components/content/app_scrollbar_theme.dart';
import 'components/feedback/app_progress_theme.dart';
import 'components/feedback/app_snackbar_theme.dart';
import 'components/feedback/app_tooltip_theme.dart';
import 'components/inputs/app_input_theme.dart';
import 'components/inputs/app_text_selection_theme.dart';
import 'components/navigation/app_app_bar_theme.dart';
import 'components/navigation/app_navigation_bar_theme.dart';
import 'components/navigation/app_tab_bar_theme.dart';
import 'components/overlays/app_popup_menu_theme.dart';
import 'components/pickers/app_date_picker_theme.dart';
import 'components/pickers/app_time_picker_theme.dart';
import 'components/selection/app_chip_theme.dart';
import 'components/selection/app_radio_theme.dart';
import 'components/selection/app_segmented_button_theme.dart';
import 'components/selection/app_slider_theme.dart';
import 'components/selection/app_toggle_themes.dart';
import 'components/surfaces/app_bottom_sheet_theme.dart';
import 'components/surfaces/app_card_theme.dart';
import 'components/surfaces/app_dialog_theme.dart';
import 'foundations/app_icon_size.dart';
import 'foundations/app_semantic_colors.dart';
import 'schemes/app_color_scheme.dart';
import 'schemes/app_high_contrast.dart';
import 'states/app_interaction_states.dart';
import 'typography/app_text_styles.dart';
import 'typography/app_typography.dart';

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
    _buildTheme(scheme, semantic);

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
    _buildTheme(scheme, semantic);

final ThemeData _lightTheme = _light(
  lightColorScheme,
  const AppSemanticColors.light(),
);

final ThemeData _darkTheme = _dark(
  darkColorScheme,
  const AppSemanticColors.dark(),
);

final ThemeData _highContrastLightTheme = _light(
  highContrastScheme(lightColorScheme),
  highContrastSemantics(const AppSemanticColors.light(), lightColorScheme),
);

final ThemeData _highContrastDarkTheme = _dark(
  highContrastScheme(darkColorScheme),
  highContrastSemantics(const AppSemanticColors.dark(), darkColorScheme),
);

/// The scheme is the only source of colour here, including the page.
///
/// **It took a `background` parameter until M100.32**, on the argument that the
/// page ground had no role because `surface` was the card sitting on it. That
/// was M3's model upside down: `surface` *is* the base ground, and the paper is
/// a container placed on it (`surfaceContainerLow`). With the ladder the right
/// way up there is no colour left for the composition root to hand in, and the
/// last piece of loose paint in the theme goes with it.
ThemeData _buildTheme(ColorScheme scheme, AppSemanticColors semantic) {
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
    scaffoldBackgroundColor: scheme.surface,
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
    canvasColor: scheme.surfaceContainerLow,
    disabledColor: semantic.onDisabled,

    // A bare `Icon` outside every themed component. Material's fallback is a
    // hardcoded black87/white pair, not even `onSurface`; declaring the
    // secondary ink at the standard glyph size means an icon nobody styled
    // degrades on-brand — the same colour every quiet glyph in the app wears.
    iconTheme: IconThemeData(
      color: scheme.onSurfaceVariant,
      size: AppIconSize.md,
    ),

    // The chrome: the two bars that frame every screen, and the one action that
    // floats over them.
    appBarTheme: buildAppBarTheme(scheme),
    navigationBarTheme: buildNavigationBarTheme(scheme, texts),
    floatingActionButtonTheme: buildFloatingActionButtonTheme(scheme),

    cardTheme: buildCardTheme(scheme),

    // Pills — `MxPillButton`. Selected borrows the navigation bar's indicator
    // pair, so "this one is active" looks the same whether it is a tab or a
    // filter; unselected is a card sitting on the page, which is the same
    // surface-over-background step every other panel uses.
    //
    // No checkmark: the pill group is always visible in full, so the selected
    // one is legible by contrast alone and the tick would shift the label
    // sideways on every change.
    chipTheme: buildChipTheme(scheme, semantic, texts),

    filledButtonTheme: buildFilledButtonTheme(scheme, semantic, texts),

    outlinedButtonTheme: buildOutlinedButtonTheme(scheme, semantic, texts),

    textButtonTheme: buildTextButtonTheme(scheme, semantic, texts),

    inputDecorationTheme: buildInputDecorationTheme(scheme, semantic, texts),

    // Four component themes added in M4.8, one per shared component that
    // renders through them — a theme for one nobody builds is a decision made
    // without a screen to check it against.
    iconButtonTheme: buildIconButtonTheme(scheme, semantic),
    listTileTheme: buildListTileTheme(scheme, semantic),
    dialogTheme: buildDialogTheme(scheme, texts),
    bottomSheetTheme: buildBottomSheetTheme(scheme),

    // The snack bar, from UC-05 — an overlay like the two above it, and the
    // reason `app_modal_themes.dart` groups the three by behaviour rather than
    // by widget class.
    snackBarTheme: buildSnackBarTheme(scheme, texts),

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
  );
}
