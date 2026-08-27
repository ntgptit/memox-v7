import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/app_spacing.dart';

/// Two actions offered together, drawn at **one size**.
///
/// **The rule this encodes: buttons that sit next to each other are the same
/// width and the same height — side by side or stacked, no exceptions.** Two
/// controls at arm's length from one another read as one choice, and a choice
/// whose options are drawn at different sizes has already been made for the
/// user by the layout. It also simply looks unfinished: the empty library
/// offered `Browse starter library` above `New deck`, each sized to its own
/// label, and the second button read as an afterthought stuck under the first
/// rather than the other half of the same question.
///
/// Left to itself neither axis gives that for free. A `Row` sizes a non-flex
/// child to its label; a `Column` under the default `CrossAxisAlignment.center`
/// does the same; `OverflowBar` — what an `AlertDialog` puts its actions in —
/// does it in both orientations. Every pair in the app therefore goes through
/// this widget instead of through a hand-built `Row`.
///
/// ## The row-or-stack decision asks the buttons, and used to guess
///
/// **Two guesses preceded this, and each was wrong in its own direction.**
///
/// The first read `MediaQuery.width − 32` — one page gutter in from the screen.
/// True of a page column, a sheet and an empty state; 96px too generous in a
/// dialog, which is `insetPadding` in from the screen *and* `actionsPadding` in
/// from its own edge. Every dialog in the app laid out a row it did not have
/// room for and let both labels wrap: `Move to Trash`, `Chuyển vào Trash`.
///
/// The second fixed the width and kept a guess about the *labels*: stack when
/// the line is under `2 × 136 + gap`, where 136 is what `Export 128 cards`
/// needs — **the widest label in the app, applied to every pair in it.** So a
/// dialog offering `Delete tag` and `Cancel` stacked too, and each of its two
/// buttons came out 265 wide for a label needing 118. The vertical cost was
/// 56px, paid on nine dialogs, for a case that only one of them has.
///
/// Neither guess was needed. **The buttons know how wide they want to be, and
/// `RenderBox` can ask them** — `getMaxIntrinsicWidth` accounts for the label,
/// the font, the text scale, the icon and the button's own padding at once,
/// with no constant to keep in step. That is what [_PairLayout] below does, and
/// it is why this widget no longer takes a minimum width or an available width:
/// the constraint it is handed *is* the line, and the children *are* the
/// measurement.
///
/// **A render object rather than a `LayoutBuilder`, and that distinction is
/// load-bearing.** `AlertDialog` lays its actions out inside an
/// `IntrinsicWidth`; `LayoutBuilder` refuses to answer an intrinsic query —
/// "calculating the intrinsic dimensions would require running the layout
/// callback speculatively" — and the dialog throws during layout. A
/// `RenderBox` answers intrinsics itself, so it can measure the line it is
/// given without that restriction.
///
/// **Width must still be bounded where this is used.** Both orientations
/// stretch, and a stretched cross axis against an unbounded constraint is an
/// error. Every call site is inside a page column, a sheet or a dialog, which
/// is where an action pair belongs anyway.
class MxButtonPair extends StatelessWidget {
  const MxButtonPair({
    required this.primary,
    required this.secondary,
    this.axis = Axis.horizontal,
    super.key,
  });

  /// The action the screen wants taken. Right in a row, **top** when stacked:
  /// the action the user came for should not be the one below the fold.
  final Widget primary;

  /// The alternative — cancel, close, the other way forward. Left in a row,
  /// under [primary] when stacked.
  final Widget secondary;

  /// [Axis.horizontal] offers the row whenever the two buttons fit in it and
  /// falls back to a stack when they do not. [Axis.vertical] always stacks.
  ///
  /// **A stack is content-width and centred, not full-bleed** (owner call,
  /// 2026-08-28): two screen-wide slabs read as a wall, not a choice. Both
  /// buttons still share one size — the wider one's — so the pair's promise
  /// holds in either orientation.
  final Axis axis;

  @override
  Widget build(BuildContext context) => _PairLayout(
    isStacked: axis == Axis.vertical,
    children: <Widget>[secondary, primary],
  );
}

/// Parent data for [_RenderPairLayout] — position only; the layout is decided
/// from the children's own intrinsic widths.
class _PairParentData extends ContainerBoxParentData<RenderBox> {}

class _PairLayout extends MultiChildRenderObjectWidget {
  /// [children] is `[secondary, primary]` — the order a row draws them in. A
  /// stack reverses it, because the action the user came for belongs on top.
  const _PairLayout({required this.isStacked, required super.children});

  final bool isStacked;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPairLayout(isStacked);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPairLayout renderObject,
  ) {
    renderObject.isForcedStack = isStacked;
  }
}

/// Lays two children out at one size, side by side when they both fit.
///
/// The whole decision is one comparison against numbers the children supply:
/// `2 × max(intrinsic width) + gap` against the line. Nothing here knows what a
/// label says, what font it is in, or what the text scale is — the children
/// already account for all three.
class _RenderPairLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PairParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PairParentData> {
  /// Positional, because a named parameter cannot be private and the field is.
  _RenderPairLayout(this._isForcedStack);

  static const double _gap = AppSpacing.sm;

  bool _isForcedStack;

  bool get isForcedStack => _isForcedStack;

  set isForcedStack(bool value) {
    if (_isForcedStack == value) return;
    _isForcedStack = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _PairParentData) {
      child.parentData = _PairParentData();
    }
  }

  RenderBox get _first => firstChild!;

  RenderBox get _second => childAfter(_first)!;

  /// The width one half wants: the wider of the two, so both can be that.
  double get _half => math.max(
    _first.getMaxIntrinsicWidth(double.infinity),
    _second.getMaxIntrinsicWidth(double.infinity),
  );

  /// **A row unless the caller asked for a column.** It used to also stack when
  /// the two labels could not be drawn in full at half the line each, which is
  /// why a delete dialog offering `Move to Trash` and `Cancel` came out as two
  /// stacked buttons: `Move to Trash` wants more than half of a 393dp footer,
  /// so the pair gave up the row.
  ///
  /// The project owner's call, and the arithmetic agrees: stacking costs two
  /// button heights plus a gap to avoid a label wrapping inside one. The labels
  /// already ellipsize at two lines, so the row's worst case is one taller
  /// button — still shorter than two, and it keeps the two options where a
  /// choice belongs, beside each other.
  ///
  /// `axis: Axis.vertical` still stacks. That is a caller stating a layout, not
  /// the pair deciding one.
  ///
  /// ## The one case that still stacks, and what it looked like without it
  ///
  /// The test is the **longest word**, not the whole label: a row survives as
  /// long as each button can still show one, because a label that wraps is
  /// readable and a label cut mid-word is not. `getMinIntrinsicWidth` is
  /// exactly that measurement for text.
  ///
  /// Dropping the fallback entirely was tried first and rendered: at 320dp and
  /// `textScaler` 2.0 the delete dialog came out as **`Ca`** beside
  /// **`Mov…`** — a destructive confirmation where neither button says what it
  /// does. That is worse than the two rows this change exists to remove.
  bool _fitsAsRow(double line) {
    if (_isForcedStack || !line.isFinite) return false;

    final widestWord = math.max(
      _first.getMinIntrinsicWidth(double.infinity),
      _second.getMinIntrinsicWidth(double.infinity),
    );

    return widestWord <= (line - _gap) / 2;
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _first.getMinIntrinsicWidth(height),
    _second.getMinIntrinsicWidth(height),
  );

  /// What the pair would take if nothing constrained it: the row, because the
  /// row is what it prefers. A parent that cannot give this much hands down a
  /// smaller constraint and [performLayout] stacks instead.
  @override
  double computeMaxIntrinsicWidth(double height) =>
      _isForcedStack ? _half : _half * 2 + _gap;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _heightFor(width, min: true);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _heightFor(width, min: false);

  double _heightFor(double width, {required bool min}) {
    final isRow = _fitsAsRow(width);
    final childWidth = isRow ? (width - _gap) / 2 : math.min(width, _half);
    double of(RenderBox child) => min
        ? child.getMinIntrinsicHeight(childWidth)
        : child.getMaxIntrinsicHeight(childWidth);
    final tallest = math.max(of(_first), of(_second));

    return isRow ? tallest : tallest * 2 + _gap;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, isDry: true);

  @override
  void performLayout() {
    size = _layout(constraints, isDry: false);
  }

  /// **Two passes on purpose.** The first asks each child how tall it is at the
  /// width it will get; the second gives both the taller of the two. That is
  /// what makes the shorter button grow to the taller one whatever made it
  /// taller — a label that wrapped at `textScaler` 2.0, most often — instead of
  /// the pair being held to a constant that is wrong at every scale but one.
  Size _layout(BoxConstraints constraints, {required bool isDry}) {
    final line = constraints.maxWidth;
    final isRow = _fitsAsRow(line);
    // Stacked buttons take the wider button's own width, not the line: two
    // screen-wide slabs read as a wall, not a choice (owner, 2026-08-28).
    // `min` keeps a long label from overflowing a narrow parent - it wraps
    // inside the line instead.
    final childWidth = isRow
        ? (line - _gap) / 2
        : (line.isFinite ? math.min(line, _half) : _half);
    final paired = line.isFinite ? line : childWidth;
    final probe = BoxConstraints(
      minWidth: childWidth,
      maxWidth: childWidth,
      maxHeight: constraints.maxHeight,
    );

    final tallest = math.max(
      _first.getMaxIntrinsicHeight(childWidth),
      _second.getMaxIntrinsicHeight(childWidth),
    );
    final tight = probe.tighten(height: tallest);

    if (isDry) {
      return constraints.constrain(
        Size(paired, isRow ? tallest : tallest * 2 + _gap),
      );
    }

    _first.layout(tight, parentUsesSize: true);
    _second.layout(tight, parentUsesSize: true);

    final firstData = _first.parentData! as _PairParentData;
    final secondData = _second.parentData! as _PairParentData;

    if (isRow) {
      firstData.offset = Offset.zero;
      secondData.offset = Offset(childWidth + _gap, 0);

      return constraints.constrain(Size(paired, tallest));
    }

    // Stacked, the order flips: `children` is `[secondary, primary]` for the
    // row, and the action the user came for belongs above the alternative.
    // Centred on the line the pair still occupies, so the choice sits where
    // the eye already is instead of hugging one edge.
    final inset = (paired - childWidth) / 2;
    secondData.offset = Offset(inset, 0);
    firstData.offset = Offset(inset, tallest + _gap);

    return constraints.constrain(Size(paired, tallest * 2 + _gap));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
