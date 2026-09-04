import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_durations.dart';
import '../../core/theme/foundations/app_motion_policy.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/typography/app_typography.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/extensions/app_ink.dart';

/// How tall the track is.
///
/// Two, not a free number. [MxProgressBarSize.sm] is the bar inside a row that
/// already carries a name and a count; [MxProgressBarSize.md] is the bar that
/// *is* the content, as a study session's own progress will be. A third would
/// be a guess, which is the same argument that keeps the icon scale at three.
enum MxProgressBarSize {
  /// **4 again** (owner review, 2026-08-20). It was 6 for a card whose track
  /// was the card's own base, seated inside a 16 corner; the gauge moved
  /// inside the surface two passes ago, so the corner argument no longer
  /// applies, and 6 was the one control height off the 4px grid.
  sm(4),
  md(8);

  const MxProgressBarSize(this.trackHeight);

  final double trackHeight;
}

/// Determinate progress — how much of a deck is learned, how far a session ran.
///
/// **It draws in its own colour family, never the accent**, and that is the whole
/// reason it is a component rather than a themed `LinearProgressIndicator`. A bar
/// filled with `primary` sits directly beside a button filled with `primary`, and
/// nothing tells the eye which of the two it can press. The fill is a lighter
/// tint of the same indigo — related to the brand, not competing with its call to
/// action.
///
/// At 100% the fill and the value label both turn `success`. That is the one
/// place this interface congratulates anybody, and it is deliberate: BR-88's
/// "learned" is a state worth marking, where every point below it is just
/// progress.
///
/// [value] is clamped rather than asserted. A caller dividing by a deck with no
/// cards is a real case — `DeckSummary.learnedFraction` returns 0 for exactly
/// that — and a bar drawn past its own track is a rendering bug shipped to a user
/// instead of a number caught in a test.

class MxProgressBar extends StatelessWidget {
  const MxProgressBar({
    required this.value,
    this.label,
    this.valueLabel,
    this.size = MxProgressBarSize.md,
    super.key,
  });

  /// 0 to 1, clamped.
  final double value;

  /// Already-localized. Shown above the bar, and used as its accessible name —
  /// a bare percentage announces a number with nothing attached to it.
  final String? label;

  /// The right-hand figure: "62%", "12 of 20". Already formatted by the caller,
  /// because plural and number formatting belong to the screen that owns the ARB
  /// entry.
  final String? valueLabel;

  final MxProgressBarSize size;

  @override
  Widget build(BuildContext context) {
    final fraction = value.clamp(0.0, 1.0);
    final isComplete = fraction >= 1;
    final semantic = context.semanticColors;
    final fill = isComplete ? semantic.success : semantic.progressFill;

    return Semantics(
      label: label,
      value: valueLabel,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (label != null || valueLabel != null) ...<Widget>[
              _MxProgressHeader(
                label: label,
                valueLabel: valueLabel,
                isComplete: isComplete,
              ),
              // `sm`, not `xs`. At 4 the figure sat on the track and the two
              // read as one object; the header is a caption *for* the bar, and
              // a caption needs enough room to be read as one.
              const SizedBox(height: AppSpacing.sm),
            ],
            ClipRRect(
              // **One shape.** A `flush` variant — the bar as a card's edge,
              // clipped by the caller — existed with zero callers (A20.1
              // P3-03); the deck tile seats the pill inside its own padding.
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: TweenAnimationBuilder<double>(
                // The bar animates to its new value rather than jumping. `slow`
                // is the app's ceiling and this is the one thing it is for: a
                // count that moved is the feedback, and a bar that snaps has
                // already finished moving by the time the user looks at it.
                //
                // **Unless the user asked it not to.** The sweep is decoration
                // on a value change, not the value itself, so reduced motion
                // collapses it to zero and the bar lands on the new figure in
                // the same frame. Nothing about the reading changes: the final
                // value, the colour and the announced label are identical.
                duration: AppMotionPolicy.durationOf(
                  context,
                  AppDurations.slow,
                ),
                curve: AppDurations.decelerate,
                tween: Tween<double>(end: fraction),
                builder: (context, animated, child) => LinearProgressIndicator(
                  value: animated,
                  minHeight: size.trackHeight,
                  backgroundColor: semantic.progressTrack,
                  color: fill,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The label and the figure above the track.
class _MxProgressHeader extends StatelessWidget {
  const _MxProgressHeader({
    required this.label,
    required this.valueLabel,
    required this.isComplete,
  });

  final String? label;
  final String? valueLabel;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        if (label != null)
          Expanded(
            child: Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: texts.labelMedium!.inked(context, AppInk.quiet),
            ),
          ),
        if (valueLabel != null) ...<Widget>[
          const SizedBox(width: AppSpacing.sm),
          Text(
            valueLabel!,
            // Through the wght axis — a bare `fontWeight:` paints the rung's
            // old weight.
            style: AppTypography.withWeight(texts.labelMedium!, FontWeight.w600)
                .inked(context, isComplete ? AppInk.success : AppInk.stated)
                .copyWith(
                  // Tabular figures so a bar that ticks 61% -> 62% does not
                  // shift the label sideways under it.
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
          ),
        ],
      ],
    );
  }
}
