import 'package:flutter/material.dart';

import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';

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
      waitDuration: const Duration(milliseconds: 500),
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
DividerThemeData buildDividerTheme(AppSemanticColors semantic) =>
    DividerThemeData(color: semantic.borderSubtle, thickness: 1, space: 1);

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
