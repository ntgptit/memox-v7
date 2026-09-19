import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/states/app_interaction_states.dart';
import '../../core/theme/typography/app_typography.dart';
import 'mx_focus_ring.dart';

/// v3's fixed-28dp one-of-N filter control, with an optional trailing count.
///
/// **Not a second `MxPillButton`.** `RawChip` clamps its painted height to a
/// ~34dp floor (`app_chip_theme.dart`), below this component's fixed 28dp
/// target, so it cannot be built on `ChoiceChip`. `primary`/`onPrimary`/
/// `border-ghost` are reserved for this component specifically so enforcing
/// them here never reaches into the shared `ChipThemeData` that
/// `ChoiceChip`/`MxPillButton` use (`docs/design-system/theme-architecture.md`).
/// The two widgets duplicate their tap-target/focus-ring plumbing rather than
/// share it — see [_TapTarget]'s doc comment.
///
/// **Selection has a shape, not only a colour**, same as `MxPillButton`: the
/// leading slot is always laid out, painting the caller's [icon] unselected
/// and a tick when selected, so toggling never reflows the pill or its
/// neighbours.
///
/// **The focus ring traces the painted 28dp shape, not the 48dp tap target**
/// grown around it — [MxFocusRing] wraps the shape, [_TapTarget] wraps that.
class MxFilterChip extends StatelessWidget {
  static const FontWeight _countWeight = FontWeight.w700;
  static const double _selectedCountOpacity = 0.75;
  static const double _unselectedCountOpacity = 0.6;

  const MxFilterChip({
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.count,
    this.icon,
    this.semanticLabel,
    super.key,
  });

  /// Already-localized. Components never reach for ARB themselves.
  final String label;

  /// Whether this chip is the active one in its group.
  final bool isSelected;

  /// Null disables the chip: paints at `AppStateOpacity.disabled` and does
  /// not respond to a tap.
  final VoidCallback? onPressed;

  /// An optional trailing numeral, rendered after [label]. `null` renders
  /// nothing and adds no gap; any other value — including `0` — renders.
  final int? count;

  /// Optional leading glyph, painted while the chip is **unselected**; the
  /// selected chip paints a tick in the same slot instead.
  final IconData? icon;

  /// Replaces [label] for assistive technology when the visible text is an
  /// abbreviation.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    final BorderRadius shapeRadius = BorderRadius.circular(AppRadius.pill);
    final RoundedRectangleBorder shape = RoundedRectangleBorder(
      borderRadius: shapeRadius,
      side: isSelected
          ? BorderSide.none
          : BorderSide(color: context.semanticColors.borderGhost),
    );

    final AppInk inkRole = isSelected ? AppInk.onPrimary : AppInk.stated;
    final IconData? glyph = isSelected ? Icons.check : icon;

    final TextStyle rung = context.texts.labelMedium!;
    final TextStyle labelStyle = rung.inked(context, inkRole);
    // Same rung, re-weighted to the count's 700 through the wght axis; the
    // colour stays the label's ink and is dimmed by `Opacity` below rather
    // than by a `copyWith(color:)` restyle (`no_text_restyle`).
    final TextStyle countStyle = AppTypography.withWeight(
      rung.inked(context, inkRole, isTabular: true),
      _countWeight,
    );
    final double countOpacity = isSelected
        ? _selectedCountOpacity
        : _unselectedCountOpacity;

    // Resolved outside the `Material` subtree: a state layer has to be
    // translucent, and R7's scan reads anything lexically inside a `Material`
    // as a translucent *fill*. `onPrimary` on the selected fill, `primary` on
    // the unselected surface; pressed only, at the one global weight.
    final Color pressedTint = isSelected
        ? context.colors.onPrimary
        : context.colors.primary;
    final WidgetStateProperty<Color?> pressedOverlay =
        WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.pressed)
              ? pressedTint.withValues(alpha: AppStateOpacity.pressed)
              : null,
        );

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isSelected,
        enabled: isEnabled,
        // One of N: the caller owns which single chip is selected.
        inMutuallyExclusiveGroup: true,
        // Focusable follows enabled, because the `Focus` under the excluded
        // subtree does: the chip stays keyboard-reachable, and a node that
        // omitted the flag described a control the tree could not explain
        // (same reasoning as `MxActionButton`).
        focusable: isEnabled,
        label: semanticLabel ?? label,
        // The count rides as the node's value ("Due, 3"): `ExcludeSemantics`
        // drops its `Text`, and composing it into the label would be a
        // user-visible string built inside a component.
        value: count?.toString(),
        onTap: onPressed,
        child: ExcludeSemantics(
          child: _TapTarget(
            child: MxFocusRing(
              borderRadius: shapeRadius,
              child: Opacity(
                opacity: isEnabled ? 1.0 : AppStateOpacity.disabled,
                child: Material(
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.surfaceContainerLowest,
                  shape: shape,
                  child: InkWell(
                    onTap: onPressed,
                    customBorder: shape,
                    overlayColor: pressedOverlay,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: SizedBox(
                        height: AppSizing.controlChip,
                        // The pill stays `controlChip` tall whatever the text
                        // scale: the Row is laid out with an unbounded height
                        // and centred, so a taller line overflows the pill
                        // symmetrically instead of being clamped to it and
                        // painted top-aligned. `deferToChild` because the
                        // default sizes to the biggest constraint, which a
                        // horizontally scrolling caller leaves infinite.
                        child: OverflowBox(
                          maxHeight: double.infinity,
                          fit: OverflowBoxFit.deferToChild,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: AppSpacing.xs,
                            children: <Widget>[
                              // Always laid out, whatever it paints — the slot
                              // is what keeps the chip's width stable across
                              // selection toggles (mx_pill_button.dart:206-215).
                              SizedBox.square(
                                dimension: AppIconSize.sm,
                                child: glyph == null
                                    ? null
                                    : Icon(
                                        glyph,
                                        size: AppIconSize.sm,
                                        color: inkRole.resolve(context),
                                      ),
                              ),
                              // No `Flexible`, no `maxLines`, no ellipsis: the
                              // caller owns horizontal scroll for overflow.
                              Text(label, style: labelStyle),
                              if (count != null)
                                Opacity(
                                  opacity: countOpacity,
                                  child: Text(
                                    count.toString(),
                                    style: countStyle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 48 × 48 finger box around a painted shape that is smaller than it.
///
/// **A verbatim copy of `MxPillButton`'s `_TapTarget`/`_RenderTapTarget`**
/// (`mx_pill_button.dart:227-331`), not an import across files or an
/// extraction into a shared primitive — extracting one would refactor
/// `MxPillButton` too, which is out of this task's stated scope. Flagged as a
/// candidate for a follow-up extraction task. **One deliberate difference:**
/// the child is laid out with `constraints.loosen()`, so a tight-height parent
/// does not override the pill's own fixed height.
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

    // Loosened: a tight parent (a 48dp scroll band) must not stretch the
    // painted shape to the box; the centring offset places it instead.
    return constraints.constrain(
      _sizeFor(child.getDryLayout(constraints.loosen())),
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(_minimum);
      return;
    }

    child.layout(constraints.loosen(), parentUsesSize: true);
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
