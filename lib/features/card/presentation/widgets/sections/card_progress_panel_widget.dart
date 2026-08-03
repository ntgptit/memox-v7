import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_state_distribution_model.dart';
import '../../../domain/models/card_state_model.dart';
import '../../controllers/card_list_filter_controller.dart';
import '../../controllers/card_progress_controller.dart';
import '../support/card_state_widget.dart';

/// The deck progress panel (D5): a mastered ring, the mastered/total line, and
/// the four-state distribution as a bar and a legend (BR-88…BR-91).
///
/// Whole-deck, not the window: it reads `cardProgressProvider`, an aggregate.
/// It renders nothing until the count arrives or when the deck is empty — an
/// empty deck shows the add-first state, not a 0% ring.
class CardProgressPanelWidget extends ConsumerWidget {
  const CardProgressPanelWidget({required this.deckId, super.key});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distribution = ref.watch(cardProgressProvider(deckId)).value;
    if (distribution == null || distribution.total == 0) {
      return const SizedBox.shrink();
    }

    // **A tinted panel, not another white card.** Every row below is an MxCard on
    // the page colour; a panel built the same way read as the first row of the
    // list rather than as the deck's summary. `primaryContainer` gives the block
    // its own ground — `onPrimaryContainer` on it measures 11.46:1 light and
    // 8.87:1 dark, and the legend dots keep their state hues, which clear the 3:1
    // a non-text mark needs (3.50 at the tightest).
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              _ProgressRing(fraction: distribution.masteredFraction),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _Headline(deckId: deckId, distribution: distribution),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _DistributionBar(distribution: distribution),
          const SizedBox(height: AppSpacing.sm),
          _Legend(distribution: distribution),
        ],
      ),
    );
  }
}

const double _ringSize = 52;
const double _ringStroke = 5;
const double _barHeight = 8;
const double _legendDotSize = 8;

/// The mastered ring with its percentage (BR-88).
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ringSize,
      height: _ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CircularProgressIndicator(
            value: fraction,
            strokeWidth: _ringStroke,
            // The arc is non-text — 3:1 is enough — so `success` carries the
            // "mastered" meaning; the track is the muted surface behind it.
            color: context.semanticColors.success,
            backgroundColor: context.semanticColors.progressTrack,
          ),
          Text(
            context.l10n.cardProgressPercent((fraction * 100).round()),
            style: context.texts.labelMedium?.copyWith(
              color: context.colors.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// The title, the mastered/total line, and what is waiting right now.
class _Headline extends ConsumerWidget {
  const _Headline({required this.deckId, required this.distribution});

  final String deckId;
  final CardStateDistributionModel distribution;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onPanel = context.colors.onPrimaryContainer;
    // The two counts the pills already read, said once more where the summary is
    // — "how far along" above, "what is waiting" below it. Null until each lands.
    final due = ref.watch(cardDueCountProvider(deckId)).value;
    final fresh = ref.watch(cardNewCountProvider(deckId)).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          context.l10n.cardProgressTitle.toUpperCase(),
          style: context.texts.labelSmall?.copyWith(
            color: onPanel,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.cardProgressMastered(
            distribution.mastered,
            distribution.total,
          ),
          style: context.texts.titleSmall?.copyWith(color: onPanel),
        ),
        if (due != null && fresh != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.cardProgressDueNew(due, fresh),
            style: context.texts.labelSmall?.copyWith(color: onPanel),
          ),
        ],
      ],
    );
  }
}

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
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        for (final state in CardState.values)
          _LegendItem(state: state, count: distribution.countOf(state)),
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
          // labelMedium on the panel's own ink: four short counts a reader scans
          // need to clear ordinary body text, and `onPrimaryContainer` measures
          // 11.46:1 light / 8.87:1 dark on the tinted ground.
          style: context.texts.labelMedium?.copyWith(
            color: context.colors.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}
