import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import 'mx_focus_ring.dart';

/// A selectable pill: the app's control for switching between a small, fixed set
/// of views of the same content.
///
/// **Why this is not one of the existing components.** `MxActionButton` performs
/// something — it has a variant ladder built around primary/destructive intent
/// and no selected state, because a button that stays pressed is a different
/// idea. `MxIconButton` has no label. `MxListTile` is a row, not an inline
/// control. Nothing in `shared/widgets/` held "one of N, and you can see which",
/// so this is the missing piece rather than a second spelling of an existing one.
///
/// **It wraps `ChoiceChip`** for the same reason `MxActionButton` wraps
/// `FilledButton` and `MxIconButton` wraps `IconButton`: Material already owns
/// the selection semantics a screen reader needs, and re-implementing them on an
/// `InkWell` is how a control ends up announcing nothing. The shape, colours and
/// border come from `chipTheme` in `app_theme.dart`, so a pill here and a pill in
/// another feature cannot drift.
///
/// The tap target is padded to [AppSizing.touchTarget]. A chip's natural
/// height is below it, and a control that is easy to see and hard to hit is worse
/// than one that is neither.
///
/// **Almost nothing about its size is decided here.** Height, corner radius,
/// horizontal padding, label style and every interaction state come from
/// `chipTheme`, so this pill and the card list's filter pills cannot drift. The
/// one exception is the gap between an icon and its label, which the theme
/// cannot state without putting the same space on a chip that has no icon.
class MxPillButton extends StatelessWidget {
  const MxPillButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.icon,
    this.semanticLabel,
    super.key,
  });

  /// Already-localized. Components never reach for ARB themselves.
  final String label;

  /// Whether this pill is the active one in its group.
  final bool isSelected;

  /// Null disables the pill. A pill with nothing to switch to should not be
  /// rendered at all, so this is for the transient case — a control whose data
  /// has not arrived — rather than for a permanent one.
  final VoidCallback? onPressed;

  /// Optional leading glyph. Decorative: the label is what is announced, and an
  /// icon that repeated it would be read twice.
  final IconData? icon;

  /// Replaces [label] for assistive technology when the visible text is an
  /// abbreviation — `A–Z` reads as two letters, not as "sort by name".
  final String? semanticLabel;

  /// The theme's chip label with `label-md`'s size, leading and tracking.
  TextStyle? _labelStyle(BuildContext context) {
    final themed = ChipTheme.of(context).labelStyle;
    final rung = Theme.of(context).textTheme.labelMedium;
    if (themed == null || rung == null) return themed;

    return themed.copyWith(
      fontSize: rung.fontSize,
      height: rung.height,
      letterSpacing: rung.letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pressed = onPressed;

    // **The focus ring is a layer around the chip, not a colour on it.**
    // `ChipThemeData.side` carries the chip's *identity* — `outlineVariant`
    // unselected, transparent selected, both from `_ChoiceChipDefaultsM3` — and
    // resolving it to `primary` on focus put a selected, focused pill on a role
    // it has no business wearing (M100.23). The wash in `_fillFor` stays and is
    // not enough on its own: 1.15:1 in light, 1.25:1 in dark, against the 3:1
    // WCAG 1.4.11 asks. `MxFocusRing` supplies the rest without touching a
    // Material colour slot.
    return MxFocusRing(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: ChoiceChip(
        // `semanticsLabel` on the Text rather than a `Semantics` wrapper around the
        // chip. Wrapping was tried and is wrong twice over: `excludeSemantics` drops
        // the chip's tap action along with its label, and without it the reader
        // announces the abbreviation *and* the expansion. Relabelling the child
        // leaves Material's own button and selected flags exactly where they were.
        // **The icon rides in the label, not in `avatar`.** Material reserves a
        // fixed leading box for an avatar and centres the glyph in it, so a 16px
        // icon came out 3 further from the edge than the 12 the theme asks for and
        // 10 from its label rather than 8 — numbers that belong to `RawChip`'s
        // internals, not to this design. Composed here, the gap is the gap.
        //
        // Nothing is lost by the move: the icon is decorative, the label is what a
        // screen reader announces, and `semanticsLabel` still rides the `Text`.
        label: _Content(icon: icon, label: label, semanticLabel: semanticLabel),
        // **One rung below the chip theme, on purpose.** `chipTheme` sets
        // `label-lg` (14), which is right for the card list's filter pills — they
        // carry counts a reader scans. These two sit in a deck list beside the
        // Study button on every row, and that button is `label-md` (12); two
        // controls of the same height in one list reading at two sizes is what
        // makes a toolbar look assembled rather than designed.
        //
        // Only the metrics come from the rung. The colour stays the theme's
        // `WidgetStateColor` — copying the rung whole would replace it with a flat
        // colour and take the disabled and selected states with it, the same trap
        // `app_chip_theme.dart` documents for `secondaryLabelStyle`.
        labelStyle: _labelStyle(context),
        selected: isSelected,
        onSelected: pressed == null ? null : (_) => pressed(),
        // Padded rather than shrinkWrap: the pill paints at [_height] and the
        // guideline minimum for a finger is 48, so the target is grown around a
        // shape that stays the size the design asks for.
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}

/// The pill's contents: an optional leading glyph, then the word.
///
/// A widget rather than a `Row` inline in [MxPillButton.build] so the icon-gap
/// decision has somewhere to be written down.
class _Content extends StatelessWidget {
  const _Content({
    required this.icon,
    required this.label,
    required this.semanticLabel,
  });

  final IconData? icon;
  final String label;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, semanticsLabel: semanticLabel);
    if (icon == null) return text;

    return Row(
      mainAxisSize: MainAxisSize.min,
      // The one gap `chipTheme` cannot state: it would land on chips with no
      // icon too, and the card list's filter pills are exactly those. `xs`
      // rather than `sm` so the glyph sits as close to its word as the deck
      // row's Study button holds its own.
      spacing: AppSpacing.xs,
      children: <Widget>[
        // Size from the icon scale, colour from **the label beside it**.
        //
        // `chipTheme.iconTheme` resolves here — an `IconTheme` wraps the
        // chip's whole label — but `ChipThemeData.iconTheme` is a plain
        // `IconThemeData` with no `WidgetStateProperty` slot, so it can only
        // state one colour for every state. It stated the resting ink, which
        // left a *selected* pill printing a brand-ink word next to a grey
        // glyph, and a *disabled* one printing a faded word next to a glyph at
        // full strength — the two halves of one control disagreeing about
        // which state it is in.
        //
        // `DefaultTextStyle` is what `RawChip` resolves `labelStyle` into, so
        // reading the colour back from it is reading the answer the theme
        // already gave: selected, disabled and resting all arrive for free,
        // and a future state does too without a second resolver to keep in
        // step. The same rule `MxTextButton` and the button themes follow —
        // `app_interaction_states_test.dart` calls it "the icon rides the
        // label through every state".
        Icon(
          icon,
          size: AppIconSize.sm,
          color: DefaultTextStyle.of(context).style.color,
        ),
        // **`Flexible`, and `mx_stress_test.dart` is why.** A bare `Text` in a
        // `Row` takes its full intrinsic width and refuses to give any back, so
        // at 320px with `textScaler` 2.0 the pill overflowed by 171. Material's
        // own `avatar` slot handled this for us; composing the row took the
        // responsibility with it.
        Flexible(child: text),
      ],
    );
  }
}
