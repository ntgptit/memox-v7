import 'package:flutter/rendering.dart';

/// Which parts of the tree the walk may skip, and why.
///
/// Two failure directions, and they are not symmetric. Measuring something that
/// never reaches the screen produces findings about pixels nobody sees — noise
/// that trains people to ignore the report. Pruning something that *is* on
/// screen produces silence, which reads as a pass. Everything here is written to
/// err in the first direction when it cannot tell.

/// The node's paint bounds in global coordinates.
Rect globalRect(RenderObject node) =>
    MatrixUtils.transformRect(node.getTransformTo(null), node.paintBounds);

/// Nothing under this node reaches the screen at all.
///
/// Neither case shows up as a clip — Flutter simply does not paint the subtree —
/// so this stays a separate question from [clipForChild].
bool isHidden(RenderObject node) {
  if (node is RenderOffstage && node.offstage) return true;
  if (node is RenderOpacity && node.opacity == 0) return true;
  if (node is RenderAnimatedOpacity && node.opacity.value == 0) return true;

  return false;
}

/// The region [child] can still paint into, given what its ancestors allow.
///
/// **Asks the render object instead of guessing from its type.** The previous
/// version decided by type and `clipBehavior`, on the assumption that a `Stack`
/// with `Clip.hardEdge` always clips. It does not: `RenderStack.paint` pushes a
/// clip only when layout found visual overflow, and layout only sees positioned
/// children — a `Transform` further down that paints outside the stack produces
/// no overflow and therefore no clip. The audit was pruning a widget Flutter was
/// plainly painting, which is a silent drop, which reads as a pass.
///
/// `describeApproximatePaintClip` is the render object's own answer to exactly
/// this question. It returns null when the child is not clipped, accounts for
/// overflow state, and honours `Clip.none`.
///
/// **Approximate is a promise about direction, not precision.** Measured: a
/// `ClipRect` with a custom clipper narrowed to 10 logical pixels still answers
/// with the node's full 50, so a widget the clipper removes stays in the
/// inventory and gets measured. That is over-reporting, and it is the direction
/// to fail in — noise in a list somebody reads, rather than a widget dropped in
/// silence. Nothing here may treat the returned rect as exact.
///
/// The result is in [parent]'s coordinate space. Note that
/// `parent.getTransformTo(null)` does **not** include a `RenderTransform`'s own
/// transform — harmless here, because a transform reports no clip at all, but it
/// is the kind of detail that has bitten this file before.
Rect clipForChild(RenderObject parent, RenderObject child, Rect inherited) {
  final local = parent.describeApproximatePaintClip(child);
  if (local == null) return inherited;

  return inherited.intersect(
    MatrixUtils.transformRect(parent.getTransformTo(null), local),
  );
}
