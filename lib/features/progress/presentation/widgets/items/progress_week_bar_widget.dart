import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../shared/widgets/mx_progress_bar.dart';

/// One day's bar in the activity chart (W4.3).
///
/// **The track is always drawn, at full width.** A day with nothing on it is
/// data, not absence (BR-186, P4): drawing nothing there would make the row look
/// like a rendering fault, and would take away the baseline every other bar is
/// read against.
///
/// **Decoration, and it says so.** The number beside it and the row's semantics
/// label carry the value; a screen reader that also read this would announce the
/// same day twice. Colour is never the only signal here — W6 requires the label
/// and the figure regardless of what the bar does.
class ProgressWeekBarWidget extends StatelessWidget {
  const ProgressWeekBarWidget({required this.fraction, super.key});

  /// How much of the track is filled, `0.0`–`1.0`.
  ///
  /// The caller divides by the window's maximum, and is the one place that can
  /// know the maximum is zero — every day empty — so the guard against dividing
  /// by it lives there rather than being re-derived per bar.
  final double fraction;

  /// Tall enough to read as a measure rather than a hairline.
  ///
  /// **Taken from [MxProgressBarSize.sm], not re-typed as `6`.** It was the
  /// literal, with a comment naming this enum as where the number came from —
  /// which is a dependency the compiler cannot see and a reader has to take on
  /// trust. The shared bar's own doc records why 6 rather than 4; a bar that
  /// borrows the reasoning should borrow the value with it.
  ///
  /// `final` rather than `const`, because Dart does not treat a field read off
  /// an enum value as a constant expression. The cost is one lazy initialiser;
  /// the alternative is re-typing the number and hoping the two stay equal.
  static final double trackHeight = MxProgressBarSize.sm.trackHeight;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return ExcludeSemantics(
      child: SizedBox(
        height: trackHeight,
        child: ClipRRect(
          // `pill`, the same token `MxProgressBar` uses. `sm` (8) rendered
          // identically here only because `ClipRRect` clamps a radius to
          // half the box and the box is 6dp tall — a coincidence that
          // would stop being one the day `MxProgressBarSize.sm` grew past
          // 16. `pill` is height-independent and says what the shape is.
          borderRadius: BorderRadius.circular(AppRadius.pill),
          // **`DecoratedBox`, not `ColoredBox`.** They draw the same rectangle,
          // and only one of them is auditable: `ColoredBox`'s render object is
          // library-private and the strict visual audit classifies it as
          // raster-only, so both of this widget's colours would have needed a
          // per-screen allowance saying "trust us". A `BoxDecoration` is read
          // straight off the render object, which is how the audit ends up
          // checking that these two really are the progress tokens in both
          // themes rather than taking the code's word for it.
          child: DecoratedBox(
            decoration: BoxDecoration(color: semantic.progressTrack),
            // `FractionallySizedBox` rather than a computed width: the track's
            // width is decided by the enclosing `Table` column, and reading it
            // here would mean a `LayoutBuilder` per row for a number the
            // framework already has. `heightFactor: 1` makes the constraint on
            // the fill tight in both axes, so the inner `DecoratedBox` needs no
            // child of its own to size against.
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: fraction.clamp(0.0, 1.0),
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: semantic.progressFill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
