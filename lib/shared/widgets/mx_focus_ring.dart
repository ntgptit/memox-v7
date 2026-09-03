import 'package:flutter/material.dart';

import '../../core/theme/states/app_interaction_states.dart';
import '../../core/theme/extensions/theme_context_extension.dart';

/// A keyboard-focus ring drawn **around** a child, in a layer of its own.
///
/// **Why this exists instead of a `side:` on the component's theme.** Material
/// gives most controls one colour slot per boundary, and that slot carries what
/// the component *is* — `outlineVariant` for a chip's edge, `outline` for a
/// switch's track. Four components in this app had been resolving that slot to
/// `primary` whenever they were focused, which meant a keyboard user tabbing
/// onto a selected chip or a switched-on toggle saw the control leave its
/// Material role (M100.23). The role and the focus state need different
/// channels, and Material only provides one — so the second one is here.
///
/// **Why not the state layer.** M3's own answer for a chip is `overlayColor` at
/// 10%, and this app composites the same wash into the fill. Measured against
/// the resting fill it reaches **1.15:1 in light and 1.25:1 in dark** — nowhere
/// near the 3:1 WCAG 1.4.11 asks of the visual information that identifies a
/// focused control. The wash is worth keeping and is not worth trusting alone.
///
/// **Why outside rather than inset.** A `BorderSide` is painted *inside* an
/// `OutlinedBorder`, so a ring on the component's own shape eats its width from
/// the fill on all four sides — the defect that made ticked checkboxes render
/// 14dp where their neighbours rendered 18 (M100.21). Drawn on the box around
/// the child, the ring costs no layout and takes nothing from the shape it
/// marks. That is the same reason CSS grew `outline` separately from `border`.
///
/// The child keeps its own size: this only adds a `foregroundDecoration`, and a
/// decoration paints without participating in layout. Nothing moves when focus
/// arrives.
///
/// **Keyboard focus only** (M100.36). `FocusHighlightMode.touch` — a phone with
/// no keyboard attached — draws no ring: focus that arrived from a tap or a
/// programmatic move is not something a touch user asked to see, and a
/// keyboard affordance without a keyboard made one control read as a
/// different component (the M99.75 defect `MxCard` already gates against;
/// `mx.css` says the same with `:focus-visible`). Flutter moves the mode to
/// `traditional` on the first key event, so a phone with a keyboard plugged in
/// gets the ring the moment it is used. One gate, in the one ring, so
/// `MxListTile`, `MxPressable` and `MxPillButton` cannot answer three ways.
class MxFocusRing extends StatefulWidget {
  const MxFocusRing({
    required this.child,
    required this.borderRadius,
    super.key,
  });

  final Widget child;

  /// The ring's corner radius. Supplied by the caller because it has to follow
  /// the shape being marked — a pill for `MxPillButton`, `AppRadius.md` for a
  /// rectangular control, zero for a full-bleed row.
  final BorderRadius borderRadius;

  @override
  State<MxFocusRing> createState() => _MxFocusRingState();
}

class _MxFocusRingState extends State<MxFocusRing> {
  bool _hasFocus = false;

  bool get _showsRing =>
      _hasFocus &&
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightModeChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightModeChanged);
    super.dispose();
  }

  void _onHighlightModeChanged(FocusHighlightMode mode) {
    // Only a focused ring has anything to redraw; an unfocused one is the
    // same picture in either mode.
    if (!_hasFocus) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // `canRequestFocus: false` and `skipTraversal: true`: this node reports on
    // its subtree, it does not join the traversal. Without both, tabbing would
    // stop here first and the child would need a second Tab to reach.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: _onFocusChange,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: _showsRing
              ? Border.fromBorderSide(
                  AppInteractionStates.focusIndicator(context.colors),
                )
              : null,
        ),
        child: widget.child,
      ),
    );
  }

  void _onFocusChange(bool hasFocus) {
    if (hasFocus == _hasFocus) return;

    setState(() => _hasFocus = hasFocus);
  }
}
