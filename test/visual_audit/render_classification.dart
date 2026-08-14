import 'package:flutter/rendering.dart';

/// Decides whether a render object is worth asking about at all.
///
/// Three buckets, and the default matters more than the other two: a type that
/// is neither vouched for here nor claimed by an extractor gets **reported**.
/// That is what makes the audit's coverage self-declaring — a painting widget
/// added next month shows up in the skip list instead of disappearing, and the
/// list is the thing that tells you an extractor is now needed.

/// Types that provably put no colour on screen: layout, clipping, semantics,
/// gesture plumbing.
///
/// Deliberately conservative. Adding a type here is a claim that it paints
/// nothing, and a wrong claim turns into a colour nobody ever checks — so the
/// default for anything not listed is to be reported, not assumed harmless.
bool renderPaintsNothing(RenderObject node) {
  return node is RenderPadding ||
      node is RenderFlex ||
      node is RenderStack ||
      node is RenderWrap ||
      node is RenderConstrainedBox ||
      node is RenderLimitedBox ||
      node is RenderPositionedBox ||
      node is RenderSizedOverflowBox ||
      // `FractionallySizedBox`. The sibling of `RenderSizedOverflowBox` above,
      // in the same file and with the same shape: it re-sizes its child and
      // inherits `RenderShiftedBox.paint`, which paints the child and nothing
      // else. Reached the audits with the Progress chart, whose fill is a
      // fraction of its track.
      node is RenderFractionallySizedOverflowBox ||
      // `Table`, **only when it draws no border**. A `RenderTable` with a
      // border, or with a decorated `TableRow`, paints those itself — so this
      // is guarded rather than blanket, and a table that grows a border starts
      // being reported again instead of quietly losing its colour check. The
      // Progress chart's table has neither.
      (node is RenderTable && node.border == null) ||
      node is RenderFittedBox ||
      node is RenderAspectRatio ||
      node is RenderBaseline ||
      node is RenderIntrinsicWidth ||
      node is RenderIntrinsicHeight ||
      node is RenderFractionalTranslation ||
      node is RenderTransform ||
      node is RenderClipRect ||
      node is RenderClipRRect ||
      node is RenderClipOval ||
      node is RenderClipPath ||
      node is RenderOffstage ||
      node is RenderIgnorePointer ||
      node is RenderAbsorbPointer ||
      node is RenderPointerListener ||
      node is RenderMouseRegion ||
      node is RenderSemanticsAnnotations ||
      node is RenderSemanticsGestureHandler ||
      node is RenderExcludeSemantics ||
      node is RenderBlockSemantics ||
      node is RenderMergeSemantics ||
      node is RenderIndexedSemantics ||
      node is RenderMetaData ||
      node is RenderRepaintBoundary ||
      node is RenderListBody ||
      node is RenderFlow ||
      node is RenderViewport ||
      node is RenderShrinkWrappingViewport ||
      node is RenderSliverPadding ||
      node is RenderSliverList ||
      node is RenderSliverFixedExtentList ||
      node is RenderSliverToBoxAdapter ||
      node is RenderCustomMultiChildLayoutBox ||
      _privateAndTransparent.contains(node.runtimeType.toString()) ||
      _annotationOnly.contains(node.runtimeType.toString());
}

/// Private render objects that paint nothing.
///
/// Matched by name because there is no type to match — Flutter keeps them
/// library-private. Fragile by construction: a rename turns into a node that
/// gets *reported*, never one that gets silently trusted, which is the only
/// direction this is allowed to fail in.
const Set<String> _privateAndTransparent = <String>{
  'RenderTapRegionSurface', // widgets/tap_region.dart, not exported
  'RenderTapRegion',
  'RenderLeaderLayer', // marks a position for a follower; paints nothing
  '_RenderTheater', // Overlay
  '_RenderScrollSemantics',
  '_RenderSingleChildViewport',
  '_RenderInputPadding', // the tap-target padding around a small control
  '_RenderCompositionCallback',
  '_RenderSizeChangedWithCallback',
  '_RenderAppBarTitleBox', // layout only; the title's own paragraph is read
  // `ListTile`'s render object. Its paint method is four `context.paintChild`
  // calls — one per slot, leading then title then subtitle then trailing — and
  // nothing else. Verified against the pinned SDK (3.44.8), not assumed. A row's
  // own surface, when it has one, is painted by the Material above it and is
  // reported separately; the label's colour is read from its paragraph.
  // Listed here rather than allowed per screen because it is a fact about
  // Flutter, not about one list — and an allowance repeated on every list
  // screen is one nobody reads by the third copy.
  '_RenderListTile',
  // `Visibility`. A `RenderProxyBox` whose `paint` either returns early or
  // delegates straight to the child — it has no colour of its own either way.
  // It reaches every screen audited through the router: `StatefulShellRoute`
  // hides the inactive branches with it.
  '_RenderVisibility',
  // `Overlay`'s depth-fixing proxy. It overrides only `redepthChildren` and
  // `performLayout` and never touches `paint`, so `RenderProxyBox.paint` paints
  // the child and nothing else. Every `Navigator` has an `Overlay`, so it
  // appears twice on any screen inside a shell route.
  '_RenderLayoutSurrogateProxyBox',
  'RenderCustomSingleChildLayoutBox',
  'RenderCustomMultiChildLayoutBox',
  // `LayoutBuilder`. A `RenderConstrainedLayoutBuilder` proxy that rebuilds
  // its child from the incoming constraints and then paints exactly that
  // child — `paint` is inherited from `RenderProxyBox` and adds nothing.
  // Reached the audits with the hero's metric grid (M99.14), whose cells are
  // half the band's measured width.
  '_RenderLayoutBuilder',
};

/// Types whose *own* paint is not a colour, but whose children are read
/// normally.
///
/// `RenderAnnotatedRegion` publishes the system UI overlay style — a status-bar
/// instruction, not pixels in this surface.
const Set<String> _annotationOnly = <String>{
  'RenderAnnotatedRegion<SystemUiOverlayStyle>',
};

/// Private render objects that DO paint, with no readable colour.
///
/// `_RenderInkFeatures` is the Material ink layer: splash and highlight are
/// painted onto it, which is why a pressed button's overlay exists in no render
/// object at all. `_RenderColoredBox` is `ColoredBox`.
const Set<String> _privateAndPainting = <String>{
  '_RenderInkFeatures',
  '_RenderColoredBox',
  // A text field: `RenderEditable` paints its own glyphs, selection and caret,
  // and `_RenderDecoration` positions a border drawn by a CustomPainter. None
  // of it is reachable as a colour — an input's stroke and its typed text are
  // raster-only, which is worth knowing before trusting an audit of a form.
  'RenderEditable',
  '_RenderEditableCustomPaint',
  '_RenderDecoration',
};

/// True when the node paints something the render tree cannot report.
bool renderPaintsRasterOnly(RenderObject node) =>
    _privateAndPainting.contains(node.runtimeType.toString());

/// Flutter's red error screen, in render-object form.
bool renderIsErrorBox(RenderObject node) => node is RenderErrorBox;
