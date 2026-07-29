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
bool isHidden(RenderObject node) {
  if (node is RenderOffstage && node.offstage) return true;
  if (node is RenderOpacity && node.opacity == 0) return true;
  if (node is RenderAnimatedOpacity && node.opacity.value == 0) return true;

  return false;
}

/// The region a child of [node] can still paint into.
///
/// Carrying this down the walk is what makes "is this on screen" answerable. A
/// node inside the capture rectangle can be entirely hidden by a `ClipRect`
/// halfway up the tree, and checking each node against the capture alone reports
/// colours for pixels that were never drawn.
Rect clipForChildren(RenderObject node, Rect inherited) {
  final own = clipRectOf(node);
  if (own == null) return inherited;

  return inherited.intersect(own);
}

/// The global rectangle this node clips its children to, or null if it does not
/// clip.
///
/// **Approximate on purpose, and only in the safe direction.** For `ClipOval`,
/// `ClipPath` and any clipper-driven `ClipRect` this returns the bounding
/// rectangle, which is a *superset* of what is actually visible. That is enough
/// to prune a subtree lying entirely outside it, and it is deliberately not
/// enough to conclude that something inside the bounding box is visible — the
/// audit keeps such nodes and measures them rather than pruning on a shape it
/// cannot see.
Rect? clipRectOf(RenderObject node) {
  // `clipBehavior`, not the type. `Stack(clipBehavior: Clip.none)` is how a
  // badge is deliberately allowed to overflow its parent; treating every Stack
  // as a clip would prune widgets that are plainly on screen.
  if (node is RenderStack) {
    return node.clipBehavior == Clip.none ? null : globalRect(node);
  }
  if (node is RenderFlex) {
    return node.clipBehavior == Clip.none ? null : globalRect(node);
  }
  if (node is RenderClipRect) {
    return node.clipBehavior == Clip.none ? null : globalRect(node);
  }
  if (node is RenderClipRRect) {
    return node.clipBehavior == Clip.none ? null : globalRect(node);
  }
  if (node is RenderClipOval) {
    return node.clipBehavior == Clip.none ? null : globalRect(node);
  }
  if (node is RenderClipPath) {
    return node.clipBehavior == Clip.none ? null : globalRect(node);
  }
  // A viewport always clips to itself; that is what makes it a viewport.
  if (node is RenderViewport) return globalRect(node);
  if (node is RenderShrinkWrappingViewport) return globalRect(node);

  return null;
}
