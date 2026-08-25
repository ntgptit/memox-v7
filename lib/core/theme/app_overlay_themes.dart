import 'package:flutter/material.dart';

import 'app_elevation.dart';
import 'app_material_roles.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_stroke.dart';

/// The themes for everything Flutter draws that the app had never named.
///
/// **The gap this closes.** `design_audit/` parses `lib/` and reports every
/// colour the code writes; its own "not verified" section says that colours
/// introduced by Material's defaults are out of its reach. That was true and it
/// was hiding real drift: the modal barrier behind every dialog and sheet was
/// `Colors.black54` — a flat grey with no relation to the seed and no change
/// between modes — because nothing had claimed it. A source scan cannot see a
/// colour that exists only as a framework default.
///
/// So these are not new design decisions. They are the app taking ownership of
/// paint it was already shipping, and the values are the tokens that were
/// already there.
///
/// Split from `app_theme.dart` because that file sits at the size guard, and
/// these belong together: every one of them is "Material had an opinion and now
/// we do".

/// How much of the page a modal hides.
///
/// Material's `black54` reads as a dead grey over a navy palette. Deriving from
/// `scrim` keeps the hue and lets dark go deeper than light, which is what the
/// two backgrounds need — a 54% black over a `#0A082D` page barely registers.
///
/// **Translucent on purpose, and exempt from the precompute rule for the same
/// reason a shadow is:** a barrier's whole job is to let the page show through
/// dimmed. There is no ground to blend against, because the ground is whatever
/// screen happens to be underneath.
Color modalBarrierColor(ColorScheme scheme) => scheme.scrim.withValues(
  alpha: scheme.brightness == Brightness.dark ? 0.72 : 0.48,
);

/// Spinners — `MxLoadingState`, and a button mid-submit.
///
/// **`focusRing`, not `primary`, and declaring this is what found out why.**
/// Material's default for a progress indicator is `colorScheme.primary`, so that
/// is what the app was already painting. Measured against the surface it spins
/// on, dark `primary` scores **2.81:1** — under the 3.0 floor a graphic needs.
/// The value was never chosen for this job: `primaryDark` is held at a luminance
/// that keeps a filled button from becoming the brightest thing on a navy page,
/// which is the opposite of what a spinner wants.
///
/// `focusRing` is the same hue at the intensity meant to pull attention — 5.36:1
/// in dark, 7.41:1 in light. It is what a focus ring and a spinner have in
/// common: both say *this, now*.
ProgressIndicatorThemeData buildProgressIndicatorTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
) => ProgressIndicatorThemeData(
  color: semantic.focusRing,
  // Explicitly transparent rather than left to default. Material draws a
  // faint track behind a circular indicator in newer versions; on a card
  // that reads as a second ring nobody asked for.
  circularTrackColor: Colors.transparent,
  linearTrackColor: scheme.surfaceContainerHighest,
);

/// How long a pointer rests before a tooltip appears.
///
/// **A component token, not a motion one, and the distinction is the point.**
/// `AppDurations` is a three-rung scale for things the user *watches* — 120 for
/// a press, 200 for a surface, 320 as the ceiling — and this is none of them: it
/// is how long the app waits before deciding a hover was a question. Adding a
/// fourth rung at 500 would have put a number on that scale that no animation
/// may use, and reading it as `AppDurations.slower` at a call site would then be
/// a motion decision nobody made.
///
/// So it lives here, beside the only theme that reads it, and it is named. What
/// it must not be is the anonymous `Duration(milliseconds: 500)` it was: a raw
/// duration is invisible to review precisely because it looks deliberate.
///
/// 500 is Material's own default, kept. Shortening it makes a tooltip fire while
/// a finger is still travelling across a toolbar of icon buttons.
const Duration kTooltipWaitDuration = Duration(milliseconds: 500);

/// The label on a long-press or hover — every `MxIconButton` and the floating
/// action have one.
///
/// `inverseSurface` and `onInverseSurface` rather than a hand-made dark box:
/// they are the M3 roles for exactly this, they already carry the seed, and they
/// invert with the mode so the tooltip stays legible in both.
TooltipThemeData buildTooltipTheme(ColorScheme scheme, TextTheme texts) =>
    TooltipThemeData(
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      textStyle: texts.labelMedium?.copyWith(color: scheme.onInverseSurface),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      waitDuration: kTooltipWaitDuration,
    );

/// Caret, selection and the drag handles in a text field.
///
/// Left to Material these come from `primary` at an opacity it chooses. Naming
/// them matters most for `selectionColor`: the default is light enough that
/// selected text on a tinted card is hard to see it is selected at all.
TextSelectionThemeData buildTextSelectionTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
) => TextSelectionThemeData(
  cursorColor: semantic.focusRing,
  selectionColor: scheme.primary.withValues(alpha: 0.24),
  selectionHandleColor: semantic.focusRing,
);

/// Hairlines between rows.
///
/// The same token a card's border uses, because they are the same idea at
/// different scales — a divider that disagreed with a card outline would make
/// one list look like two.
/// `space` equals `thickness`, so a divider occupies exactly the line it draws
/// and adds no padding of its own — Material's default reserves 16.
DividerThemeData buildDividerTheme(AppSemanticColors semantic) =>
    DividerThemeData(
      color: semantic.borderSubtle,
      thickness: AppStroke.hairline,
      space: AppStroke.hairline,
    );

/// The scroll thumb.
///
/// Long lists are the app's main surface, so the thumb is on screen often. Left
/// to Material it is a neutral grey with no seed in it.
ScrollbarThemeData buildScrollbarTheme(ColorScheme scheme) =>
    ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll<Color>(
        scheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
      radius: const Radius.circular(AppRadius.sm),
      thickness: const WidgetStatePropertyAll<double>(4),
    );

/// The time picker, as the reminder screen's `showTimePicker` renders it.
///
/// **The one dialog in the app that does not inherit `dialogTheme`, which is
/// why it needs its own entry.** `TimePickerDialog` builds its `Dialog` from
/// `_TimePickerDefaultsM3` rather than from the theme every other dialog reads:
/// elevation 6, a 28px radius and a `surfaceContainerHigh` background. So
/// without this the reminder flow opened the single surface in the app that
/// carries a Material shadow and a different corner — while `dialogTheme`
/// spends a paragraph on why dialogs are `elevation: 0` with a hairline (see
/// F15 and AD-14).
///
/// The values below are `dialogTheme`'s, restated in the slots this component
/// happens to read. Nothing here is a new decision; every one of them is the
/// app's existing answer arriving somewhere it was not being asked.
///
/// **The number fields are the exception, and they are a real decision.** M3
/// gives the hour and minute a `primaryContainer` fill when selected. That is
/// already the app's answer for a selected control — the navigation bar's
/// indicator and the filter pills use the same pair — so it stays, and the ink
/// on it is [selectedInk], which is the function that exists precisely because
/// the right ink on that fill differs by brightness: 5.57:1 in light and
/// 8.87:1 in dark, where a single token would have shipped 2.13:1 in one of
/// them.
TimePickerThemeData buildTimePickerTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) {
  final selected = selectedInk(scheme);

  return TimePickerThemeData(
    backgroundColor: scheme.surface,
    // Zero, and a hairline instead — the same trade `dialogTheme` makes, for
    // the same reason: AD-14 admits one depth mechanism and this app spends it
    // on the surface ladder.
    elevation: AppElevation.none,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: semantic.borderSubtle),
    ),
    padding: const EdgeInsets.all(AppSpacing.xl),
    helpTextStyle: texts.labelLarge?.copyWith(color: scheme.onSurfaceVariant),

    // The dial. Its face is the inset-tile surface, so the ring of numbers
    // reads as a panel within the sheet rather than as a hole in it.
    // **`WidgetStateColor`, not `WidgetStateProperty<Color>`.** Every slot in
    // `TimePickerThemeData` is typed `Color?` rather than a state property, so
    // the per-state values have to arrive as a Color subclass. Writing the
    // property form here does not compile, which is the good outcome; writing
    // a flat colour compiles and silently drops the selected state, which is
    // the one to watch for.
    dialBackgroundColor: semantic.surfaceMuted,
    dialHandColor: scheme.primary,
    dialTextColor: WidgetStateColor.resolveWith((states) {
      // The number the hand is on sits ON the hand, so it takes the fill's
      // partner: 7.51:1 in light, 5.88:1 in dark.
      if (states.contains(WidgetState.selected)) return scheme.onPrimary;

      return scheme.onSurface;
    }),
    dialTextStyle: texts.bodyLarge,

    // The hour and minute fields above the dial.
    hourMinuteColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return scheme.primaryContainer;

      return semantic.surfaceMuted;
    }),
    hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return selected;

      return scheme.onSurface;
    }),
    hourMinuteTextStyle: texts.displaySmall,
    hourMinuteShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),

    // AM/PM. Only some locales show it, which is exactly why it is themed
    // rather than left out: a component nobody sees in `en` is one an
    // `en_US` reviewer sees on the first screenshot.
    // **`tertiaryContainer`, which is M3's role here and not the one this
    // theme first used.** It shipped as `primaryContainer` — the app's answer
    // for *a selected control* — and that is the right answer to the wrong
    // question. M3 gives the hour/minute field `primaryContainer` and AM/PM
    // `tertiaryContainer` on purpose: they are two different questions
    // ("which unit am I editing" and "morning or afternoon") and one fill for
    // both loses the distinction the component is drawn to make.
    //
    // **What adopting it buys here is less than it should be, and the number
    // is worth recording rather than discovering later.** Against
    // `primaryContainer` the app's `tertiaryContainer` measures **1.10:1 in
    // light and 1.29:1 in dark** — the two containers differ in hue but barely
    // in lightness, so the distinction reads as a tint rather than as a
    // separation. That is a property of a hand-tuned palette whose tertiary
    // carries 8.8 chroma against primary's 14.5, not of this mapping: the fix,
    // if the owner wants the distinction to carry, is a tone on
    // `tertiaryContainer`, not a different role in this file.
    //
    // It also gives the tertiary family its first renderer. Until now it was
    // declared only so `fromSeed` could not invent it.
    dayPeriodColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return scheme.tertiaryContainer;
      }

      return Colors.transparent;
    }),
    dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
      // 9.75:1 in light, 7.24:1 in dark on the fill above.
      if (states.contains(WidgetState.selected)) {
        return scheme.onTertiaryContainer;
      }

      return scheme.onSurfaceVariant;
    }),
    dayPeriodTextStyle: texts.titleMedium,
    dayPeriodBorderSide: BorderSide(color: semantic.borderControl),
    dayPeriodShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: BorderSide(color: semantic.borderControl),
    ),

    // **`inputDecorationTheme` is deliberately left to Material.** The picker's
    // keyboard-entry mode draws the hour and minute as display-scale fields;
    // `buildInputDecorationTheme` is padded and radiused for a 16px body
    // field, and forcing it on them would be a layout decision made without a
    // screen to check it against — which is the one thing this file's own rule
    // refuses. It becomes worth deciding the day a mock shows that mode.
    entryModeIconColor: scheme.onSurfaceVariant,
  );
}

/// The overflow menu — `PopupMenuButton`, on four call sites: the card list's
/// import/export menu, the bulk-action bar, a tag row and the sort control.
///
/// **Found by `theme_coverage_test.dart` rather than by reading the code, and
/// that is the point of that test.** Two hand greps missed all four, because
/// every one is written `PopupMenuButton<CardListSort>(` and a name-then-paren
/// search does not match a generic call. Until this landed, four menus rendered
/// on `surfaceContainer` with a Material shadow and a 4px corner while every
/// other surface in the app sat on `surface` at `elevation: 0` with a hairline.
///
/// The values are `dialogTheme`'s and `bottomSheetTheme`'s — a menu is a small
/// sheet, so it takes the same paper. `AppRadius.md` rather than M3's 4: this
/// app's corner scale starts at 8 and a 4px menu beside a 12px button reads as
/// a different kit.
PopupMenuThemeData buildPopupMenuTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => PopupMenuThemeData(
  color: scheme.surface,
  surfaceTintColor: Colors.transparent,
  // Zero plus a hairline, for the reason F15 and AD-14 give: one depth
  // mechanism, and this app spends it on the surface ladder.
  elevation: AppElevation.none,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    side: BorderSide(color: semantic.borderSubtle),
  ),
  labelTextStyle: WidgetStateProperty.resolveWith((states) {
    final base = texts.bodyMedium;
    if (states.contains(WidgetState.disabled)) {
      return base?.copyWith(color: semantic.onDisabled);
    }

    return base?.copyWith(color: scheme.onSurface);
  }),
  // The menu is a list of destinations, so its rows wash like rows rather than
  // like controls — the same weight `MxListTile` resolves.
  menuPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
);
