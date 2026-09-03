import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
/// **It is one of an exclusive group, and only that** (M100.36 4N). A command
/// that happens to sit beside pills — the card list's tag-filter entry, which
/// opens a sheet — is an `MxActionButton`, not a pill wearing a selected state
/// it does not have: five identical semantics nodes in one row, four of them
/// mutually exclusive and one an independent toggle, told a screen reader
/// nothing about which was which (#434 P1-1).
///
/// **It wraps a flat `ChoiceChip`** for the same reason `MxActionButton` wraps
/// `FilledButton` and `MxIconButton` wraps `IconButton`: Material already owns
/// the selection semantics a screen reader needs, and re-implementing them on an
/// `InkWell` is how a control ends up announcing nothing. The shape, colours and
/// border come from `chipTheme`, so a pill here and a pill in another feature
/// cannot drift.
///
/// **Flat, not `.elevated`** (M100.36 11A). M100.32 chose the elevated
/// constructor "so the unselected pill takes `surfaceContainerLow` from the
/// canonical role". That is not what happens: `ChipThemeData.color`
/// short-circuits `chipDefaults.color` entirely (`chip.dart:1529-1531` at
/// 3.44.8), so the variant never supplied the fill — `buildChipTheme` did, and
/// still does. The variant's only live effect was to swap `shadowColor` from
/// transparent to `scheme.shadow`, and with `pressElevation` left at M3's 1.0
/// every unselected pill cast a real drop shadow while pressed: a second depth
/// mechanism AD-14 does not admit, arrived at by a note that said it was
/// removing one (#434 P1-2). `mx_pill_button_construction_test.dart` pins the
/// constructor at source.
///
/// **Selection has a shape, not only a colour** (M100.36 4M, #434 P1-3). The
/// leading slot is always laid out: it paints a tick when the pill is selected
/// and the caller's [icon] — or nothing — when it is not, so the pill's outer
/// size does not change on toggle and its neighbours do not slide. That is the
/// 20dp reflow Material's own `showCheckmark` costs, which is why
/// `chipTheme` turns it off and the tick is composed here instead. W6's
/// "not colour alone" is met without a per-caller `Icons.check`.
///
/// **The focus ring traces the pill, not the finger's box** (M100.36 11C, #434
/// P1-4). `RawChip` with `MaterialTapTargetSize.padded` wraps its painted body
/// in a 48 × 48 hit box, and a ring drawn around *that* floated 7dp clear of a
/// short pill at a different corner. The chip is built `shrinkWrap`, the ring
/// wraps the painted shape, and the 48 target is restored *outside* the ring
/// by [_TapTarget] — the same redirecting pad `ButtonStyleButton` uses — so
/// the ring and the target are two separate geometry facts.
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

  /// Optional leading glyph, painted while the pill is **unselected**; the
  /// selected pill paints the tick in the same slot, which is what Material's
  /// own chip does with its avatar. Decorative: the label is what is announced,
  /// and an icon that repeated it would be read twice.
  final IconData? icon;

  /// Replaces [label] for assistive technology when the visible text is an
  /// abbreviation — `A–Z` reads as two letters, not as "sort by name".
  final String? semanticLabel;

  /// The theme's chip label with `label-md`'s size, leading and tracking.
  ///
  /// **A closed shared widget may specialise a rung; a feature may not**
  /// (M100.36 4P). `chipTheme` sets `label-lg`, which is right for a bare
  /// `Chip` in the tag editor; these pills sit in a deck list beside the Study
  /// button on every row, and that button is `label-md` — two controls of the
  /// same height in one list reading at two sizes is what makes a toolbar look
  /// assembled rather than designed. Only the metrics come from the rung; the
  /// colour stays the theme's `WidgetStateColor`, because copying the rung
  /// whole would replace it with a flat colour and take the disabled and
  /// selected states with it.
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

    // Merged so the one node carries the chip's button, selected and enabled
    // flags, the exclusivity stated here, and the *48dp* rect of the tap
    // target — `androidTapTargetGuideline` reads the node's rect, and the
    // chip's own node would report the 34-tall painted shape.
    return MergeSemantics(
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        child: _TapTarget(
          child: MxFocusRing(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: ChoiceChip(
              // `semanticsLabel` on the Text rather than a `Semantics` wrapper
              // around the chip. Wrapping was tried and is wrong twice over:
              // `excludeSemantics` drops the chip's tap action along with its
              // label, and without it the reader announces the abbreviation
              // *and* the expansion. Relabelling the child leaves Material's
              // own button and selected flags exactly where they were.
              //
              // **The glyph rides in the label, not in `avatar`.** Material
              // reserves a fixed leading box for an avatar and centres the
              // glyph in it, so a 16px icon came out 3 further from the edge
              // than the 12 the theme asks for and 10 from its label rather
              // than 8 — numbers that belong to `RawChip`'s internals, not to
              // this design. Composed here, the gap is the gap.
              label: _Content(
                icon: icon,
                label: label,
                semanticLabel: semanticLabel,
                isSelected: isSelected,
              ),
              labelStyle: _labelStyle(context),
              selected: isSelected,
              onSelected: pressed == null ? null : (_) => pressed(),
              // The target is [_TapTarget]'s, outside the ring — see the class
              // note. `padded` here would put the 48 box *inside* the ring.
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ),
    );
  }
}

/// The pill's contents: the leading slot, then the word.
///
/// A widget rather than a `Row` inline in [MxPillButton.build] so the icon-gap
/// and the check-slot decisions have somewhere to be written down.
class _Content extends StatelessWidget {
  const _Content({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.isSelected,
  });

  final IconData? icon;
  final String label;
  final String? semanticLabel;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    // Size from the icon scale, colour from **the label beside it**.
    //
    // `chipTheme.iconTheme` resolves here — an `IconTheme` wraps the chip's
    // whole label — but `ChipThemeData.iconTheme` is a plain `IconThemeData`
    // with no `WidgetStateProperty` slot, so it can only state one colour for
    // every state. It stated the resting ink, which left a *selected* pill
    // printing a brand-ink word next to a grey glyph, and a *disabled* one
    // printing a faded word next to a glyph at full strength — the two halves
    // of one control disagreeing about which state it is in.
    //
    // `DefaultTextStyle` is what `RawChip` resolves `labelStyle` into, so
    // reading the colour back from it is reading the answer the theme already
    // gave: selected, disabled and resting all arrive for free.
    final Color? ink = DefaultTextStyle.of(context).style.color;
    final IconData? glyph = isSelected ? Icons.check : icon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      // The one gap `chipTheme` cannot state: it would land on chips with no
      // icon too, and the tag editor's raw chips are exactly those. `xs`
      // rather than `sm` so the glyph sits as close to its word as the deck
      // row's Study button holds its own.
      spacing: AppSpacing.xs,
      children: <Widget>[
        // **Always laid out, whatever it paints.** The slot is what keeps the
        // pill's width the same selected and unselected — the tick arrives in
        // room that was already there (M100.36 4M). A `SizedBox` with a null
        // child is a 16 × 16 box; an `Icon` at the same size fills it exactly.
        SizedBox.square(
          dimension: AppIconSize.sm,
          child: glyph == null
              ? null
              : Icon(glyph, size: AppIconSize.sm, color: ink),
        ),
        // **`Flexible`, and `mx_stress_test.dart` is why.** A bare `Text` in a
        // `Row` takes its full intrinsic width and refuses to give any back, so
        // at 320px with `textScaler` 2.0 the pill overflowed by 171. Material's
        // own `avatar` slot handled this for us; composing the row took the
        // responsibility with it.
        Flexible(child: Text(label, semanticsLabel: semanticLabel)),
      ],
    );
  }
}

/// The 48 × 48 finger box around a painted shape that is smaller than it.
///
/// **The same redirecting pad `ButtonStyleButton` keeps as `_InputPadding`,
/// and `RawChip` as `_ChipRedirectingHitDetectionWidget`.** Both are private
/// to the SDK; this one exists so the pill can put its focus ring *between*
/// the target and the shape. A tap that lands in the padding is redirected to
/// the child's centre, so the chip's own `InkWell` runs its ripple and its
/// haptic exactly as if the finger had hit the shape — the target grows the
/// area, never the paint.
class _TapTarget extends SingleChildRenderObjectWidget {
  const _TapTarget({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTapTarget();
}

class _RenderTapTarget extends RenderShiftedBox {
  _RenderTapTarget() : super(null);

  static const Size _minimum = Size.square(AppSizing.touchTarget);

  @override
  double computeMinIntrinsicWidth(double height) {
    final child = this.child;
    final double width = child?.getMinIntrinsicWidth(height) ?? 0;

    return width < _minimum.width ? _minimum.width : width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final child = this.child;
    final double width = child?.getMaxIntrinsicWidth(height) ?? 0;

    return width < _minimum.width ? _minimum.width : width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final child = this.child;
    final double height = child?.getMinIntrinsicHeight(width) ?? 0;

    return height < _minimum.height ? _minimum.height : height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final child = this.child;
    final double height = child?.getMaxIntrinsicHeight(width) ?? 0;

    return height < _minimum.height ? _minimum.height : height;
  }

  Size _sizeFor(Size childSize) => Size(
    childSize.width < _minimum.width ? _minimum.width : childSize.width,
    childSize.height < _minimum.height ? _minimum.height : childSize.height,
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.constrain(_minimum);

    return constraints.constrain(_sizeFor(child.getDryLayout(constraints)));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(_minimum);
      return;
    }

    child.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(_sizeFor(child.size));
    final BoxParentData childParentData = child.parentData! as BoxParentData;
    childParentData.offset = Alignment.center.alongOffset(
      size - child.size as Offset,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null || !size.contains(position)) return false;
    if (super.hitTest(result, position: position)) return true;

    // In the padding: hand the event to the shape's centre, so the chip's own
    // ink and feedback run — exactly what `_ChipRedirectingHitDetection` did
    // for the box it used to own.
    final Offset center = child.size.center(Offset.zero);
    final BoxParentData childParentData = child.parentData! as BoxParentData;
    final Offset target = childParentData.offset + center;

    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(target),
      position: target,
      hitTest: (BoxHitTestResult result, Offset position) {
        assert(position == target);
        return child.hitTest(result, position: center);
      },
    );
  }
}
