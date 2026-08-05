import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
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

    // A flat bordered card, the same surface every row below it uses (MxCard, no
    // shadow inside a scrolling list). The tinted ground was tried and reverted:
    // a block of colour at the top of the list outweighed the cards under it,
    // which are what the screen is actually about.
    return MxCard(
      elevation: AppElevation.none,
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
          _StudyAction(deckId: deckId),
        ],
      ),
    );
  }
}

/// The panel's primary action: begin a review over what is due.
///
/// **Only when something is due**, the rule the deck card already follows: a
/// deck with nothing waiting has no verb to offer, and a disabled Study button
/// says "you cannot" where the truth is "there is nothing to". It is the one
/// filled `primary` control on this screen, because it is the one thing a
/// learner comes here to do.
///
/// The session itself is M5; until then the tap says so, exactly as
/// `deck_study_button_widget.dart` does — one place to change when the review
/// screen lands.
///
/// **It never says "due" about a card nobody has seen.** BR-22's queue is
/// `due_at IS NULL OR due_at <= now`, so a card created a minute ago is in it —
/// and the state table in `business-rules.md` calls that same card `new`, not
/// `due`. The button used to read the queue and print it as "N due", which on a
/// deck holding one untouched card said a review had come back around when
/// nothing had been introduced yet, and the line above it then counted that one
/// card twice ("1 due · 1 new"). The queue is what the session hands over, so
/// the count stays the queue; only the verb branches on whether any of it has
/// been reviewed before.
class _StudyAction extends ConsumerWidget {
  const _StudyAction({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queued = ref.watch(cardDueCountProvider(deckId)).value ?? 0;
    if (queued == 0) return const SizedBox.shrink();

    // `new` is a subset of the queue — BR-09 creates a review state with
    // `due_at = NULL` and BR-77 fills it on the first `scheduled` review, so
    // `review_count = 0` implies `due_at IS NULL`. Anything left over is a card
    // that has been through a session and come back around.
    final fresh = ref.watch(cardNewCountProvider(deckId)).value ?? 0;
    // Zero until the count lands, which reads as "some of this has been seen"
    // and gives the neutral label — the honest one to show while unsure.
    final hasReturningCards = queued > fresh;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: FilledButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.deckStudyComingSoonMessage)),
        ),
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size.fromHeight(AppSpacing.minimumTouchTarget),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xs,
          children: <Widget>[
            const Icon(Icons.play_arrow, size: AppIconSize.sm),
            Text(
              hasReturningCards
                  ? context.l10n.cardProgressStudyAction(queued)
                  : context.l10n.cardProgressLearnAction(queued),
              // `onPrimary` stated, not inherited: a style taken from the text
              // theme carries the body colour and would land dark ink on the
              // brand fill — the 2.33:1 the deck button already paid for once.
              style: context.texts.labelMedium?.copyWith(
                color: context.colors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
            style: context.texts.labelMedium,
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

  /// "What is waiting", with each card counted once.
  ///
  /// [queued] is BR-22's queue and [fresh] is BR-90's never-reviewed set, which
  /// sits inside it — so the number this line may call *due* is the difference,
  /// the state table's `due`: reviewed before, ripe again. Printing the queue
  /// beside `fresh` is what made one untouched card read as "1 due · 1 new".
  ///
  /// Three complete sentences rather than one assembled from parts: the
  /// separator, the order and the pluralisation of "due" and "new" all differ
  /// per language, so a `+ ' · ' +` here is untranslatable. Null when neither
  /// number has anything to report — the deck is finished for now, and a line
  /// of zeroes is noise.
  String? _waitingLine(BuildContext context, int queued, int fresh) {
    final returning = queued - fresh;
    if (returning > 0 && fresh > 0) {
      return context.l10n.cardProgressDueNew(returning, fresh);
    }
    if (returning > 0) return context.l10n.cardProgressDueOnly(returning);
    if (fresh > 0) return context.l10n.cardProgressNewOnly(fresh);

    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiet = context.colors.onSurfaceVariant;
    // The two counts the pills already read, said once more where the summary is
    // — "how far along" above, "what is waiting" below it. Null until each lands.
    final queued = ref.watch(cardDueCountProvider(deckId)).value;
    final fresh = ref.watch(cardNewCountProvider(deckId)).value;
    final waiting = queued == null || fresh == null
        ? null
        : _waitingLine(context, queued, fresh);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          context.l10n.cardProgressTitle.toUpperCase(),
          style: context.texts.labelSmall?.copyWith(
            color: quiet,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.cardProgressMastered(
            distribution.mastered,
            distribution.total,
          ),
          style: context.texts.titleSmall,
        ),
        if (waiting != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            waiting,
            style: context.texts.labelSmall?.copyWith(color: quiet),
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
