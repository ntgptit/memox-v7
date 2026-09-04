import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/foundations/app_stroke.dart';

/// The three shapes a loading state takes, closed (A20.1 P1-02).
enum _MxLoadingShape {
  /// Centred in whatever space it is given, with a gutter — a body that is
  /// nothing but "loading".
  fullArea,

  /// The indicator alone, for a column that lays it out with its own text and
  /// spacing — the import steps' "parsing…" panel.
  inColumn,

  /// Sixteen dp, the stroke of a button's spinner — a row's trailing "more is
  /// coming" mark.
  inline,
}

/// The loading state.
///
/// **One owner for the accessible name.** A bare `CircularProgressIndicator`
/// announces nothing — the user is told neither that something is happening
/// nor when it stops — so every shape here takes an already-localized
/// [semanticsLabel] and hands it to the indicator. Six feature sites wrote the
/// spinner themselves before A20.1 P1-02, in three shapes, and one of them had
/// no name at all.
///
/// Three constructors rather than a size parameter: the shapes differ in
/// layout, not in a number, and a `double` here would be the next open axis.
class MxLoadingState extends StatelessWidget {
  /// Centred in whatever space it is given.
  const MxLoadingState({required this.semanticsLabel, super.key})
    : _shape = _MxLoadingShape.fullArea;

  /// The indicator alone, for a column that owns the layout around it.
  const MxLoadingState.inColumn({required this.semanticsLabel, super.key})
    : _shape = _MxLoadingShape.inColumn;

  /// The 16 dp inline mark.
  const MxLoadingState.inline({required this.semanticsLabel, super.key})
    : _shape = _MxLoadingShape.inline;

  final String semanticsLabel;
  final _MxLoadingShape _shape;

  @override
  Widget build(BuildContext context) {
    // The indicator animates for as long as it is on screen, and a
    // `markNeedsPaint` travels up to the nearest repaint boundary — without
    // one that is the enclosing layer, so *everything* sharing it repaints
    // on every frame of the spin.
    //
    // Measured: a sibling `CustomPaint` beside this widget was painted once
    // more per animation frame (10 extra paints over 10 frames). With the
    // boundary the spinner gets its own layer and the sibling is painted
    // once. The cost is one render object; the alternative is the whole
    // loading screen repainting at 60fps to move one arc.
    //
    // **No `color:` here on purpose.** It used to pass
    // `context.colors.primary`, which quietly overrode
    // `buildProgressIndicatorTheme` — the theme M4.10j introduced *because*
    // dark `primary` measures 2.81:1 against the surface it spins on,
    // under the 3.0 floor a graphic needs. Letting the theme supply the
    // colour is the fix, and it is the same rule the repo applies everywhere
    // else: correct it at the rule, not at the call site.
    final Widget indicator = RepaintBoundary(
      child: switch (_shape) {
        _MxLoadingShape.inline => SizedBox.square(
          dimension: AppIconSize.sm,
          child: CircularProgressIndicator(
            strokeWidth: AppStroke.indicator,
            semanticsLabel: semanticsLabel,
          ),
        ),
        _ => CircularProgressIndicator(semanticsLabel: semanticsLabel),
      },
    );

    return switch (_shape) {
      _MxLoadingShape.fullArea => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: indicator,
        ),
      ),
      _MxLoadingShape.inColumn || _MxLoadingShape.inline => indicator,
    };
  }
}
