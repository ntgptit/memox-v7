import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme/foundations/app_sizing.dart';

/// The 48 × 48 finger box around a painted shape that is smaller than it
/// (`AppSizing.touchTarget` on both axes, the child centred).
///
/// **The same redirecting pad `ButtonStyleButton` keeps as `_InputPadding`,
/// and `RawChip` as `_ChipRedirectingHitDetectionWidget`.** Both are private
/// to the SDK; this one exists so a control can put its focus ring *between*
/// the target and the shape. A tap that lands in the padding is redirected to
/// the child's centre, so the child's own `InkWell` runs its ripple and its
/// haptic exactly as if the finger had hit the shape — the target grows the
/// area, never the paint. A plain `ConstrainedBox` + `Center` would size the
/// box but add no pointer hits: the padding would be layout only.
///
/// Moved out of `mx_pill_button.dart` unchanged in behaviour once a second
/// control (`MxChipTrigger`) needed it.
class MxTapTarget extends SingleChildRenderObjectWidget {
  const MxTapTarget({required super.child, super.key});

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
