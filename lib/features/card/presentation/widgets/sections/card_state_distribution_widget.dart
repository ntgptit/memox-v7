import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_state_distribution_model.dart';
import '../../../domain/models/card_state_model.dart';
import '../support/card_state_widget.dart';

/// How a deck's cards are spread across the four states (D5, BR-89…BR-91):
/// one proportional bar, and the legend that names its colours.
///
/// **Split out of `card_progress_panel_widget.dart` when that file crossed the
/// 400-line guard**, on the seam the guard's own advice points at: these two
/// widgets are one statement — the bar shows the proportions and the legend
/// names them, and neither is meaningful without the other. The panel composes
/// a ring, this, and an action; those are three separate ideas.
class CardStateDistributionWidget extends StatelessWidget {
  const CardStateDistributionWidget({required this.distribution, super.key});

  final CardStateDistributionModel distribution;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: <Widget>[
        _DistributionBar(distribution: distribution),
        _Legend(distribution: distribution),
      ],
    );
  }
}

const double _barHeight = 8;
const double _legendDotSize = 8;

/// The distribution as one bar of coloured segments, sized by count (D5).
class _DistributionBar extends StatelessWidget {
  const _DistributionBar({required this.distribution});

  final CardStateDistributionModel distribution;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.cardProgressDistributionSemantics(
        distribution.isNew,
        distribution.beginning,
        distribution.reviewing,
        distribution.mastered,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        child: SizedBox(
          height: _barHeight,
          child: Row(
            children: <Widget>[
              for (final state in CardState.values)
                if (distribution.countOf(state) > 0)
                  Expanded(
                    flex: distribution.countOf(state),
                    child: ColoredBox(color: context.cardStateColor(state)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The legend: each state's dot, name and count (BR-89…BR-91).
class _Legend extends StatelessWidget {
  const _Legend({required this.distribution});

  final CardStateDistributionModel distribution;

  @override
  Widget build(BuildContext context) {
    // **Two fixed columns, not a `Wrap`.** The four items need 372 across and
    // the panel gives them 326, so a `Wrap` put three on one line and left
    // `Mastered` alone on the next — a ragged break that reads as a mistake
    // rather than as a layout. Two by two is the same information in two even
    // rows, and the columns line up because each cell takes half the width
    // instead of its own.
    //
    // Down the rows in `CardState` order, so it still reads New → Beginning →
    // Reviewing → Mastered left to right, top to bottom.
    const states = CardState.values;

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: <Widget>[
        for (var row = 0; row < states.length; row += 2)
          Row(
            spacing: AppSpacing.md,
            children: <Widget>[
              for (var column = 0; column < 2; column++)
                Expanded(
                  child: _LegendItem(
                    state: states[row + column],
                    count: distribution.countOf(states[row + column]),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.state, required this.count});

  final CardState state;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: _legendDotSize,
          height: _legendDotSize,
          decoration: BoxDecoration(
            color: context.cardStateColor(state),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          context.l10n.cardProgressLegendItem(
            context.cardStateLabel(state),
            count,
          ),
          // labelMedium on onSurface: four short counts a reader scans need to
          // clear ordinary body text, and the muted variant sat under it.
          style: context.texts.labelMedium?.copyWith(
            color: context.colors.onSurface,
          ),
        ),
      ],
    );
  }
}
