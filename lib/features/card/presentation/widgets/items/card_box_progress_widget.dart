import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_radius.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../study/domain/models/eight_box_scheduler.dart';

/// `eight_box`'s position, drawn as the eight steps it actually has.
///
/// **Only `eight_box` gets this.** SM-2 has no box ladder — its progress is
/// three numbers that only mean something together — so forcing it into a track
/// would be inventing a metric the algorithm does not define (AD-08, BR-243).
/// The panel renders this widget or it renders nothing.
///
/// **Colour is not the only signal, and in dark it cannot be.** Completed steps
/// take `progressFill`, the current one `primary`, the rest `progressTrack`. In
/// light those are three distinct values; in **dark** `progressFillDark` *is*
/// `primaryDark` — so the current step is told apart by being taller, and the
/// panel states `Box N / 8` in words directly above the track.
/// A reader who cannot see the difference is never relying on it.
class CardBoxProgressWidget extends StatelessWidget {
  const CardBoxProgressWidget({
    required this.currentBox,
    required this.maxBox,
    super.key,
  });

  /// 1-based, and already known to be non-null by the panel.
  final int currentBox;

  /// From the scheduler contract, never a literal at the call site.
  final int maxBox;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Row(
      children: <Widget>[
        // **Both ends come from the contract.** The ceiling was already read
        // from `kMaxBox`; the floor was a literal `1`, so a re-numbered ladder
        // would have shifted the track by one step while the badge stayed
        // right.
        for (var box = kMinBox; box <= maxBox; box++) ...<Widget>[
          if (box > kMinBox) const SizedBox(width: _segmentGap),
          Expanded(
            child: Container(
              height: box == currentBox ? _currentHeight : _stepHeight,
              decoration: BoxDecoration(
                color: switch (box.compareTo(currentBox)) {
                  < 0 => semantic.progressFill,
                  0 => context.colors.primary,
                  _ => semantic.progressTrack,
                },
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The gap between two steps.
///
/// `AppSpacing.xs`, so the track is built from the same scale as everything
/// beside it rather than from a number chosen to look right at one width.
const double _segmentGap = AppSpacing.xs;

/// A step the card is not on.
///
/// Not a token: this is the track's own line weight, the same way a divider's
/// hairline belongs to the divider. Six and ten keep the current step visibly
/// heavier at every text scale, because neither grows with the scaler — the
/// track is a graphic, and a graphic that scaled with type would break the
/// eight-across grid at 2.0.
const double _stepHeight = 6;

/// The step the card is on now.
const double _currentHeight = 10;
