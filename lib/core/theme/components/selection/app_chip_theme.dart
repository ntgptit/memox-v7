import 'package:flutter/material.dart';

import '../actions/app_button_themes.dart';
import '../../foundations/app_elevation.dart';
import '../../foundations/app_icon_size.dart';
import '../../states/app_interaction_states.dart';
import '../../foundations/app_radius.dart';
import '../../foundations/app_semantic_colors.dart';
import '../../foundations/app_sizing.dart';
import '../../foundations/app_spacing.dart';
import '../../typography/app_typography.dart';

/// The chip theme — `MxPillButton`'s entire appearance.
///
/// Split from `app_theme.dart` when that file crossed the 400-line guard, on the
/// same seam `app_button_themes.dart` was cut on: one component family, every
/// interaction state declared by hand, read by nothing else in the theme.
///
/// **Every state is resolved here, and that is a correction rather than polish.**
/// This theme used to declare `backgroundColor` and `selectedColor` and nothing
/// else, which left Material to answer for the rest — and Material's answers are
/// exactly the kind AD-05 rule 5 calls invisible to a source scan:
///
/// * a **disabled** pill fell through to `onSurface` at 12% *alpha*, composited
///   against whatever was behind it at paint time. That is the translucency
///   MX-VIS-002 rule R7 exists to stop, arrived at by not writing anything down.
/// * a **disabled and selected** pill kept the full `secondaryContainer` fill,
///   because `_IndividualOverrides` returns `selectedColor` for that pair before
///   the defaults are consulted. A pill nobody could press looked exactly as
///   live as one they could.
/// * **hover, focus and press** had no chip-level answer at all, so a pill
///   responded to a pointer by a different amount than every button beside it.
///
/// Declaring the state-aware [ChipThemeData.color] is what takes ownership of
/// all four: it is consulted before `backgroundColor`, `selectedColor` and
/// `disabledColor`, which is why those three are deliberately *not* set — two
/// spellings of one fill, one of them dead, is how the next edit changes the
/// colour in the half nothing reads.

/// The resting fill for a pill, before any pointer or disabled state.
///
/// Selected is `secondaryContainer` — `_ChoiceChipDefaultsM3.color`'s answer,
/// and the same pair the navigation indicator and the segmented button take, so
/// "this one is active" looks the same whether it is a tab, a segment or a
/// filter.
///
/// **Unselected is `surfaceContainerLow` — the paper — and this theme is what
/// paints it** (M100.36, correcting M100.32). `_ChoiceChipDefaultsM3.color` is
/// variant-dependent — a flat `ChoiceChip` has no unselected fill, the elevated
/// one fills with `surfaceContainerLow` — and M100.32 reasoned that building
/// the elevated variant would "take the role from the SDK". It does not:
/// `ChipThemeData.color` short-circuits `chipDefaults.color` before either
/// variant is consulted (`chip.dart:1529-1531`), so this resolver has owned the
/// fill all along and the variant only ever changed the *shadow*. The pill is
/// a flat chip whose paper fill is stated here, on the canonical slot, in the
/// canonical role (#434 P1-2).
///
/// It read `scheme.surface` until M100.32, which was the paper only because the
/// app read `surface` as the paper. `surface` is the page now, and the same
/// pixels come from the rung that means paper.
///
/// **It was `primaryContainer` between the owner review of 2026-08-20 and
/// M100.22, and the review's complaint was real**: at `#E4E6EC` an applied
/// filter and an unapplied one were nearly the same rectangle on a light page —
/// 7.39 L\* of step against the paper, where the brand container gave 10.34. The
/// error was fixing that on the component. M100.22 moved the *tone* instead
/// (`AppMaterialRoles.secondaryContainerLight`), so the role now gives 10.50 and
/// the chip can say what it is.
Color _restingFill(ColorScheme scheme, {required bool isSelected}) =>
    isSelected ? scheme.secondaryContainer : scheme.surfaceContainerLow;

/// The fill for [states], resolved to a solid colour over the ground that state
/// actually has.
///
/// Blended rather than washed over: R7 asks for `Color.alphaBlend` at build
/// time, and here the ground is known — a pill's fill is the only thing under
/// its own feedback.
Color _fillFor(ColorScheme scheme, Set<WidgetState> states) {
  final resting = _restingFill(
    scheme,
    isSelected: states.contains(WidgetState.selected),
  );

  // **Disabled is M3's own answer, selected or not** (M100.36 11H):
  // `_ChoiceChipDefaultsM3.color` resolves *both* disabled combinations to
  // `onSurface @ 12%` over the ground, which is `disabledSurfaceTint` over the
  // paper. Blending it over the *selected* fill instead — what this resolver
  // did until M100.36 — kept the container tint under the grey, and in dark
  // that lightens: a disabled selected pill measured 2.04:1 against the page
  // where a live one measured 1.56:1, *more* prominent for being switched
  // off (#434 P2-3). The selected identity is carried by the tick the pill
  // composes and by `Semantics(selected:)`, both of which survive disabling;
  // the fill's job is to recede, and one fill for both recedes honestly.
  if (states.contains(WidgetState.disabled)) {
    return disabledSurfaceTint(scheme);
  }
  // **Hover only, and only because `RawChip` owns it** (M100.36 4O, #434
  // P2-6). The moment a theme supplies `color`, `chip.dart:1427` forces the
  // `InkWell`'s `hoverColor` to transparent — so a hover fill composed here is
  // the pill's *only* hover. Press and focus are different: the chip's
  // `InkWell` still paints `ThemeData.splashColor` and `focusColor` for them,
  // and this resolver used to tint the fill by the same amounts on top, so a
  // press ran at ~24% effective where the token said 12. One transient
  // mechanism per state: Material's ripple for press, Material's wash plus the
  // external ring for focus, this fill for hover.
  if (states.contains(WidgetState.hovered)) {
    return _tint(resting, scheme.primary, AppStateOpacity.hoverControl);
  }

  return resting;
}

Color _tint(Color ground, Color tint, double alpha) =>
    Color.alphaBlend(tint.withValues(alpha: alpha), ground);

/// The label colour for [states].
///
/// **Carried by `labelStyle.color` as a [WidgetStateColor], and `secondaryLabelStyle`
/// is left null on purpose.** `ChoiceChip` passes `secondaryLabelStyle` down as the
/// widget's own label style when selected, and it is merged *over* this one — so a
/// plain `Color` there would win for the selected pill and take the disabled and
/// pressed states with it. One state machine, in the slot Material resolves.
Color _labelColorFor(
  ColorScheme scheme,
  AppSemanticColors semantic,
  Set<WidgetState> states,
) {
  if (states.contains(WidgetState.disabled)) {
    return semantic.onDisabled;
  }
  if (states.contains(WidgetState.selected)) {
    return scheme.onSecondaryContainer;
  }

  return scheme.onSurfaceVariant;
}

/// The weight a chip label is set in — the one property where the chip parts
/// from `label-lg`, and the only rung-level exception in the app.
///
/// **A chip is not a button, and `label-lg` is the button's weight.** This app
/// sets `label-lg` at 600 where Material 3 sets it at 500, deliberately and for
/// `FilledButton`: a label reversed out of a solid fill needs the extra stroke.
/// `ChipThemeData` reads the same rung, so the pill inherited a raise that was
/// argued for a surface it does not have — it sits on the page behind a hairline
/// at 1.50:1, with no fill carrying it.
///
/// **Measured on a device render, not judged from the code.** At the same 14px
/// as the search field's hint the pill labels covered 0.340 and 0.364 of their
/// glyph box against the hint's 0.271 — 26-34% more ink at an identical
/// ascender height of 27px. That put two toggles at ranks 2 and 3 in the
/// screen's ink hierarchy, under the deck name (0.409) and over the section
/// heading they belong to, `Show today's summary`, and the search field.
///
/// 500 is Material's own chip weight, and `--weight-medium` in the kit, so this
/// rejoins a spec rather than inventing a value. Size, leading and tracking stay
/// `label-lg`: the label was never the wrong *size*.
const FontWeight _chipLabelWeight = FontWeight.w500;

/// `label-lg` re-weighted, with the state-aware colour Material resolves.
TextStyle? _labelStyle(
  TextTheme texts,
  ColorScheme scheme,
  AppSemanticColors semantic,
) {
  final rung = texts.labelLarge;
  if (rung == null) {
    return null;
  }

  return AppTypography.withWeight(rung, _chipLabelWeight).copyWith(
    color: WidgetStateColor.resolveWith(
      (states) => _labelColorFor(scheme, semantic, states),
    ),
  );
}

ChipThemeData buildChipTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => ChipThemeData(
  color: WidgetStateProperty.resolveWith((states) => _fillFor(scheme, states)),
  // **Zero at rest and zero while pressed.** AD-14 admits one depth mechanism
  // and it is `shadowsFor`; `_ChoiceChipDefaultsM3.pressElevation` is 1.0 and
  // was reachable — measured `Material.elevation` 0 → 1 on every unselected
  // press with a real `shadowColor` under it (#434 P1-2). Stated on both slots
  // so neither can come back through a constructor default.
  elevation: AppElevation.none,
  pressElevation: AppElevation.none,
  // No Material checkmark: with `showCheckmark: true` the avatar slot opens
  // 20dp on selection and every pill after it slides. The tick is composed in
  // `MxPillButton`'s leading slot, which is laid out in *both* states, so
  // selection has a shape without a reflow (M100.36 4M).
  showCheckmark: false,
  // **Selected is read first, and the order is the contract rather than a
  // style.** `_ChoiceChipDefaultsM3.side` decides on `isSelected` before it
  // looks at anything else, so a chip that is selected *and* focused is still a
  // selected chip. This resolver used to ask about focus first and paint a
  // `primary` ring, which meant one state combination — the one a keyboard user
  // is in whenever they tab onto an applied filter — silently left the
  // canonical role. That is the bug class M100.23 exists to close: an
  // interaction state may add feedback, it may not change what a slot *means*.
  //
  // Focus is not lost by removing it from here. It is carried by the fill, in
  // `_fillFor` above, which tints the resting colour by `AppStateOpacity.focus`
  // — and a state layer is exactly where M3 puts a chip's focus cue.
  side: WidgetStateBorderSide.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      // **No edge when selected, in every combination.**
      // `_ChoiceChipDefaultsM3.side` returns a transparent side for a selected
      // chip whether or not it is enabled: the fill is what says "applied", and
      // an edge in a third colour makes the pill a different shape from its
      // unselected neighbours as well as a different colour.
      return const BorderSide(color: Colors.transparent);
    }
    if (states.contains(WidgetState.disabled)) {
      // The same value as the disabled fill, by construction: a disabled pill
      // recedes into one grey and its edge says nothing — which is the
      // canonical `onSurface @ 12%` chip too (#434 P2-2, accepted).
      return BorderSide(color: disabledSurfaceTint(scheme));
    }
    // `outlineVariant`, which is what `borderSubtle` had been aliasing — the
    // two are the same value, and M3 names this slot the decorative one. It
    // measures 1.24:1 against the paper: below the 3:1 WCAG 1.4.11 asks of a
    // boundary that *identifies* a component, and deliberately so — the pill
    // is identified by its shape, its label, its group and, when picked, its
    // tick, the same exemption a card's edge takes (#434 P2-4, P2-5). Inside
    // a sheet the fill equals the ground and this hairline is the only edge;
    // `mx_pill_button_construction_test.dart` renders that case.
    // The width is `BorderSide`'s default, and the default *is*
    // `AppStroke.hairline` — stating it here trips `avoid_redundant_argument_values`,
    // so the equality is pinned in `mx_pill_button_theme_test.dart` instead
    // (#434 P3-2).
    return BorderSide(color: scheme.outlineVariant);
  }),
  // **Pill, kept.** `AppRadius.sm` is named "chips, badges, small indicators"
  // and going to it was tried — the owner looked at the render and kept the
  // pill. The reason holds up beside the numbers: at 32 tall the chip is now the
  // same height as the deck row's Study button, which is also fully rounded, and
  // two controls that size alike in one list should not shape differently.
  //
  // `AppRadius.pill`, not `StadiumBorder`: same painted shape, but the pill
  // radius is how every other fully-rounded control in the app says it
  // (`MxSearchField`, `MxMetricWell`, the progress bar), and one result should
  // not have two mechanisms.
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.pill),
  ),
  labelStyle: _labelStyle(texts, scheme, semantic),
  // **The fall-through only, and it cannot be more than that.**
  // `ChipThemeData.iconTheme` is a plain `IconThemeData` with no
  // `WidgetStateProperty` slot, so one colour has to serve every state — and
  // the resting ink is the honest choice for a bare `Chip`'s avatar or delete
  // glyph, which is the only thing left reading it. `MxPillButton` paints its
  // own glyph in the resolved *label* colour instead, because a selected pill
  // printing brand ink beside a grey glyph is one control disagreeing with
  // itself. See the note at its `Icon`.
  iconTheme: IconThemeData(
    size: AppIconSize.sm,
    color: scheme.onSurfaceVariant,
  ),
  // **`labelPadding` zeroed, and that is the fix for the skew rather than a
  // tightening.** Material lays a chip out as
  // `padding.left | avatar | labelPadding.left | label | labelPadding.right |
  // padding.right`, and its default `labelPadding` is 8 on BOTH sides. With an
  // avatar that put 8 of unasked-for space on the trailing edge only: the
  // toolbar pills measured 11 left of the icon against 17 right of the label,
  // which reads as a control shunted left rather than one with even sides.
  // Zeroing it makes `padding` the only thing between the edge and the content,
  // so 12 means 12. A chip that wants space between an icon and its label asks
  // for it explicitly — see `MxPillButton`.
  labelPadding: EdgeInsets.zero,
  // 12 across is M3's own chip padding once `labelPadding` is not double-counting
  // it. Vertical is derived, not chosen: the app's `label-lg` line box is 20, so
  // `(32 - 20) / 2` is what makes the content box 32 — the height M3 draws a chip
  // at, and a multiple of 4 like every other size here. The two hairlines sit
  // outside it, so a ruler laid on the painted shape reads 34.
  //
  // **Stated even though Material would arrive at 32 anyway.** `RawChip` clamps
  // its height to a 34-painted floor, which was measured by dropping this value
  // to a deliberate 3 and watching nothing move. Leaving the padding under that
  // floor would make the theme say one thing and the render do another, and the
  // first person to raise the label size would find the chip growing from a
  // number nobody wrote down.
  //
  // **Padding rather than a fixed height.** At `textScaler` 2.0 the line box
  // passes 40; a pinned height would clip it, and the 320x568 screen tests run at
  // exactly that scale. 32 is the resting height, not a ceiling.
  padding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: _verticalPadding,
  ),
);

/// The chip's content box — M3's chip height, and what a design spec means by
/// "32dp tall". The two hairlines sit outside it, so the painted shape measures
/// 34; the tap target is [AppSizing.touchTarget] and is grown around
/// both, never instead of them.
const double _containerHeight = 32;

/// The `label-lg` line box the vertical padding is derived from.
const double _labelLineHeight = 20;

const double _verticalPadding = (_containerHeight - _labelLineHeight) / 2;
