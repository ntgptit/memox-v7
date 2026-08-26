import 'package:flutter/material.dart';

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
/// **How the sizes are made equal, and why not with a fixed number.** Width
/// comes from `Expanded` — two children of equal flex split the line, or take
/// the column's full width when stacked — so the pair fills the space its
/// caller gives it and never invents a width of its own. Height comes from
/// `IntrinsicHeight` wrapping a flex whose children are both `Expanded`:
/// `RenderFlex`'s main-axis intrinsic is `totalFlex × max(childSize / flex)`,
/// which is `2 × max(h₁, h₂)` plus the gap, and the two `Expanded` children
/// then divide that back into two equal halves. So the shorter button grows to
/// the taller one whatever made it taller — a label that wrapped to two lines
/// at `textScaler` 2.0, most often — rather than the pair being held to a
/// constant that is wrong at every scale but one.
///
/// **The row-or-stack decision reads `MediaQuery`, and deliberately not a
/// `LayoutBuilder`.** Measuring the line the pair is actually given would be
/// more precise, and it is not available: `AlertDialog` lays its actions out
/// inside an `IntrinsicWidth`, `LayoutBuilder` refuses to answer an intrinsic
/// query — "calculating the intrinsic dimensions would require running the
/// layout callback speculatively" — and the dialog throws during layout. The
/// widget under it must therefore answer intrinsics, which `Flex`,
/// `IntrinsicHeight` and `Expanded` all do. The screen's width minus one page
/// gutter each side is the approximation, and it holds because an action pair
/// always sits in something that tracks the screen: a page column, a sheet, a
/// dialog.
///
/// **Except in a dialog, where the approximation is 96px wrong.** A dialog is
/// not one page gutter in from the screen — it is `insetPadding` in from the
/// screen *and* `actionsPadding` in from its own edge. On a 393 screen the
/// footer is 265 wide while this widget assumed 361, which is above the
/// stacking threshold, so it laid out a row and let both labels wrap to two
/// lines instead. That shipped in every dialog in the app — `Move to Trash`,
/// `Chuyển vào Trash` — and it looked like a copy problem rather than a
/// measurement one, which is why it survived a layout review of 29 screens.
///
/// So a caller that knows better may say so through [availableWidth]. Callers
/// that sit directly in a page column, a sheet or an empty state leave it null
/// and keep the screen-width approximation, which is right for them.
///
/// **Width must be bounded where this is used.** Both orientations stretch, and
/// a stretched cross axis against an unbounded constraint is an error. Every
/// call site is inside a page column, a sheet or a dialog, which is where an
/// action pair belongs anyway.
class MxButtonPair extends StatelessWidget {
  const MxButtonPair({
    required this.primary,
    required this.secondary,
    this.axis = Axis.horizontal,
    this.minButtonWidth = defaultMinButtonWidth,
    this.availableWidth,
    super.key,
  });

  /// The action the screen wants taken. Right in a row, **top** when stacked:
  /// the action the user came for should not be the one below the fold.
  final Widget primary;

  /// The alternative — cancel, close, the other way forward. Left in a row,
  /// under [primary] when stacked.
  final Widget secondary;

  /// [Axis.horizontal] offers the row first and falls back to a stack when the
  /// screen is too narrow for it. [Axis.vertical] always stacks — for a pair
  /// that is a choice between two full-width paths rather than a footer.
  final Axis axis;

  /// The narrowest half a label stays readable in, before type scaling.
  ///
  /// The fallback threshold, not a minimum applied to the buttons: below
  /// `2 × minButtonWidth × textScale + gap` the pair stacks instead of
  /// squeezing both labels into two lines apiece. 136 is the width
  /// `Export 128 cards` needs at 1.0×, measured for the export sheet and the
  /// widest real label in the app.
  final double minButtonWidth;

  static const double defaultMinButtonWidth = 136;

  /// The width the pair actually gets, when the caller knows it and the screen
  /// does not imply it.
  ///
  /// Null means "one page gutter in from the screen on each side", which is
  /// true of a page column, a sheet and an empty state. A dialog must pass its
  /// own footer width — see the note above.
  final double? availableWidth;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: _shouldStack(context)
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: primary),
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: secondary),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: secondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: primary),
            ],
          ),
  );

  bool _shouldStack(BuildContext context) {
    if (axis == Axis.vertical) return true;

    // The scale, not the raw width: at `textScaler` 2.0 a 360dp screen has the
    // same pixels and half the room, and the row that fits at 1.0× is the one
    // that ellipsizes `Merge tags` at 2.0×.
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final line =
        availableWidth ?? MediaQuery.sizeOf(context).width - AppSpacing.lg * 2;

    return line < minButtonWidth * scale * 2 + AppSpacing.sm;
  }
}
