import 'package:flutter/material.dart';

import 'app_elevation.dart';
import 'app_interaction_states.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_stroke.dart';

/// Themes for four components this app does not render yet.
///
/// **This is a deliberate exception to the rule the rest of the theme follows,
/// and the exception has a shape.** `app_theme.dart` says a theme for a
/// component nobody renders is a decision made without a screen to check it
/// against. That is true of a theme that *decides* something. It is not true of
/// one that only *restates* decisions already made and already checked — which
/// is exactly what the time picker turned out to be when it was written, and
/// what all four below are.
///
/// So the admission test for this file is narrow, and three of it must hold:
///
/// 1. **Every colour is already decided.** Not one line here picks a value; each
///    reads a token whose reasoning lives elsewhere and whose contrast is
///    already measured.
/// 2. **The component is named in this project's own roadmap**, not guessed at
///    from what a flashcard app might one day be — `docs/wbs.md`'s deferred
///    list and `CLAUDE.md`'s "deliberately deferred" paragraph.
/// 3. **Material's own default is wrong for this app in a way already
///    established.** Each one below either bypasses `dialogTheme` the way the
///    time picker does, or resolves a selected state from a pair this app
///    replaced.
///
/// A component that fails any of the three stays out, and the ones that did are
/// worth naming: `badgeTheme` (a due count is either the warm *due* family or
/// the red *overdue* one, and BR-161 settled that they are different signals —
/// which is a decision, so it needs a screen); `navigationRailTheme` and
/// `drawerTheme` (AD-04 ships no large-screen layout and forbids branching on
/// one); `menuTheme` and `menuBarTheme` (the anchored-menu API, which this app
/// does not use — its overflow menus are `PopupMenuButton`, and that one is
/// themed for real in `app_overlay_themes.dart` because it has four callers).
///
/// **`popupMenuTheme` was on this list as "not our idiom" and that was simply
/// wrong** — the app builds four of them. `theme_coverage_test.dart` is what
/// said so, after two hand greps had missed every one; each call site is
/// written `PopupMenuButton<CardListSort>(`, and a name-then-paren search does
/// not match a generic call. Worth keeping in the record: the reason a
/// component was excluded is as capable of being wrong as the theme itself.
///
/// **When one of these gains a renderer, its theme moves out of this file** and
/// into the slot list in `app_theme.dart` with the others. The file is a
/// waiting room, not a second home.

/// The date picker — the reminder screen's likely companion to the time picker,
/// and the history range in `docs/wbs.md`'s deferred *study answers* screen.
///
/// **The same bug as the time picker, verified rather than assumed.**
/// `_DatePickerDefaultsM3.backgroundColor` is `surfaceContainerHigh` and the
/// dialog it builds carries Material's elevation, so a date picker opened today
/// would be the one surface in the app with a shadow and a foreign corner —
/// exactly what `buildTimePickerTheme` exists to stop. Everything below is
/// `dialogTheme`'s answer arriving in the slots this component reads.
DatePickerThemeData buildDatePickerTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) {
  final selected = scheme.onPrimaryContainer;

  return DatePickerThemeData(
    backgroundColor: scheme.surface,
    elevation: AppElevation.none,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: semantic.borderSubtle),
    ),
    headerForegroundColor: scheme.onSurfaceVariant,
    weekdayStyle: texts.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
    dayStyle: texts.bodyMedium,
    dayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return semantic.onDisabled;
      if (states.contains(WidgetState.selected)) return scheme.onPrimary;

      return scheme.onSurface;
    }),
    dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return scheme.primary;

      return null;
    }),
    dayOverlayColor: AppInteractionStates.controlOverlay(scheme),
    // Today is a ring, not a fill — M3's own answer, and the one that keeps a
    // filled day meaning *selected* and nothing else.
    todayBorder: BorderSide(
      color: scheme.primary,
      width: AppStroke.selectionControl,
    ),
    todayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return scheme.onPrimary;

      return scheme.primary;
    }),
    // A range is a run of days, so it takes the selection tint the pills and
    // the navigation indicator already use rather than a second one.
    rangeSelectionBackgroundColor: scheme.primaryContainer,
    rangePickerHeaderForegroundColor: scheme.onSurfaceVariant,
    yearForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return selected;

      return scheme.onSurfaceVariant;
    }),
    yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return scheme.primaryContainer;

      return null;
    }),
    dividerColor: semantic.borderSubtle,
  );
}

/// The segmented button — a range switch (week / month / year) on the deferred
/// progress and study-history screens.
///
/// **`primaryContainer` / `onPrimaryContainer`, because this app has one answer
/// for "this segment is the active one" and it is already drawn twice.** M3 uses
/// the `secondaryContainer` pair; the owner's review (2026-08-20) moved the
/// app's active state to the brand container, which is what the navigation
/// bar's indicator and `MxPillButton` both render. A third answer here would
/// make the same question look different on three screens.
///
/// The label is the container's own `on` role — the M3 pairing — rather than
/// `primary`, which is a fill and not the ink for a fill.
SegmentedButtonThemeData buildSegmentedButtonTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
) => SegmentedButtonThemeData(
  style: ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return states.contains(WidgetState.selected)
            ? semantic.disabledSurface
            : Colors.transparent;
      }
      if (states.contains(WidgetState.selected)) return scheme.primaryContainer;

      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return semantic.onDisabled;
      if (states.contains(WidgetState.selected)) {
        return scheme.onPrimaryContainer;
      }

      return scheme.onSurfaceVariant;
    }),
    overlayColor: AppInteractionStates.controlOverlay(scheme),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return AppInteractionStates.focusRing(scheme);
      }

      return BorderSide(color: semantic.borderControl);
    }),
    shape: WidgetStatePropertyAll<OutlinedBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
    minimumSize: const WidgetStatePropertyAll<Size>(
      Size.fromHeight(AppSpacing.minimumTouchTarget),
    ),
  ),
);

/// The slider — `CLAUDE.md` names SM-2 parameters as deliberately deferred, and
/// a bounded numeric parameter is what a slider is for.
///
/// **The filled half is `focusRing`, not `primary`, and that is the third time
/// this palette has forced the same correction.** M3 fills the active track
/// with `primary` and the rest with `secondaryContainer`, and this theme was
/// written that way. Measured, M3's own pairing scores **6.02:1 in light and
/// 2.11:1 in dark** — under the 3:1 a slider's value needs, because
/// `primaryDark` is deliberately held between the surfaces and the text (see
/// `AppColors.primaryDark`) and *no* neutral in the dark palette reaches 3:1
/// from it: the best, `surfaceMuted`, is 2.45.
///
/// Since M100.18 the fix is the role itself: `primary` against
/// `secondaryContainer` reads **6.02:1 light and 7.31:1 dark**, and against the
/// card behind it 7.27:1 and 10.02:1. The inactive half keeps M3's role; the
/// active half now keeps it too, which is the point of moving the palette
/// rather than the component.
///
/// **This reverses the argument this file first shipped**, which was that a
/// slider is pressable so it takes the accent while a progress bar does not.
/// The premise is still right — a slider is a control — but pressability is
/// carried by the thumb, not by the hue, and the hue has a contrast job that
/// `primary` cannot do on a dark card. A test pins the M3 pairing as failing,
/// so the reason cannot decay back into a preference.
///
/// The value indicator takes the inverse pair — the same surface a snack bar
/// uses, and for the same reason: it is a momentary overlay that has to read
/// against whatever it covers.
SliderThemeData buildSliderTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => SliderThemeData(
  activeTrackColor: scheme.primary,
  // `secondaryContainer` is M3's, and it is also the one neutral fill in this
  // palette that is not already a surface tier — so the inactive half cannot be
  // mistaken for the card behind it.
  inactiveTrackColor: scheme.secondaryContainer,
  thumbColor: scheme.primary,
  disabledActiveTrackColor: semantic.disabledSurface,
  disabledInactiveTrackColor: semantic.disabledSurface,
  disabledThumbColor: semantic.disabledSurface,
  // White on the filled track: 7.66:1 in light, 3.09:1 in dark. The dark
  // figure is the tightest number in this file and it clears the graphic
  // floor, which is the right floor — a tick is a mark on a track, not text.
  activeTickMarkColor: scheme.onPrimary,
  inactiveTickMarkColor: scheme.onSecondaryContainer,
  overlayColor: scheme.primary.withValues(alpha: AppStateOpacity.pressed),
  valueIndicatorColor: scheme.inverseSurface,
  valueIndicatorTextStyle: texts.labelMedium?.copyWith(
    color: scheme.onInverseSurface,
  ),
);

/// The tab bar — the card detail screen's deferred *History* view, which
/// `docs/wbs.md` records as blocked on a study-answers screen rather than on a
/// design.
///
/// **`primary` for the selected label, which is M3's own answer and was not
/// available until M100.18.** A tab's label sits on the page or a card, not on a
/// selection fill, so it wants the brand hue as a label — and the old dark fill
/// tone could not be one, at 3.33:1 on the page against the 4.5:1 text needs. A
/// separate accent token carried it until the palette inverted; `primary` now
/// measures 11.36:1 there.
TabBarThemeData buildTabBarTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => TabBarThemeData(
  labelColor: scheme.primary,
  unselectedLabelColor: scheme.onSurfaceVariant,
  labelStyle: texts.titleSmall,
  unselectedLabelStyle: texts.titleSmall,
  indicatorColor: scheme.primary,
  indicatorSize: TabBarIndicatorSize.tab,
  // The hairline under the whole bar, which is the same line every other band
  // in the app is separated by.
  dividerColor: semantic.borderSubtle,
  dividerHeight: AppStroke.hairline,
  overlayColor: AppInteractionStates.controlOverlay(scheme),
);
