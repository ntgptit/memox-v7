import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/card_state_distribution_model.dart';
import '../../controllers/card_list_filter_controller.dart';
import '../../controllers/card_progress_controller.dart';
import 'card_state_distribution_widget.dart';

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
          CardStateDistributionWidget(distribution: distribution),
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
/// nothing had been introduced yet.
///
/// **The queue is now added back rather than read directly.** `Due` and `New`
/// are two disjoint pills — `CardListFilter.due` subtracts New from the queue —
/// so the number a session would hand over is their sum, and it is assembled
/// here because that is where it is needed. The button says what will happen:
/// the whole queue when some of it has been reviewed before, and "learn" when
/// none of it has.
class _StudyAction extends ConsumerWidget {
  const _StudyAction({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Disjoint by construction, so this addition is the queue and not an
    // approximation of it — see `duePredicate` in `card_list_query_mapper.dart`.
    final due = ref.watch(cardDueCountProvider(deckId)).value ?? 0;
    final fresh = ref.watch(cardNewCountProvider(deckId)).value ?? 0;
    final queued = due + fresh;
    if (queued == 0) return const SizedBox.shrink();

    // Both counts are zero until their streams land, so the button renders
    // nothing at all rather than guessing at a verb — the panel around it is
    // already on screen by then, and a label that flips once the second count
    // arrives is worse than one that appears a frame late.
    final hasReturningCards = due > 0;

    return Padding(
      // `xl`, not `lg`: this is the break between reading the deck and acting on
      // it, and at 16 the button sat as close to the last legend row as the two
      // legend rows sit to each other. A section break should not measure the
      // same as the gap inside a section.
      padding: const EdgeInsets.only(top: AppSpacing.xl),
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

/// **64, up from 52 — and the drawn ring was never 52 anyway.** The box was that
/// size, but `CircularProgressIndicator` inside a `Stack` takes its own
/// intrinsic size and centres, so it painted at Material's default **36** with
/// 16 of dead space around it. That is why the ring read as small and the
/// percentage looked lost inside a panel this wide: the number was never the one
/// in the source.
///
/// `Positioned.fill` below makes the arc actually take the box, so 64 is 64.
const double _ringSize = 64;

/// Scaled with the ring so the arc keeps its weight rather than thinning out as
/// the circle grows.
const double _ringStroke = 6;

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
          // `Positioned.fill`, not a bare child: an indicator in a `Stack` sizes
          // itself and centres, so without this the arc ignores the box it was
          // given.
          Positioned.fill(
            child: CircularProgressIndicator(
              value: fraction,
              strokeWidth: _ringStroke,
              // The arc is non-text — 3:1 is enough — so `success` carries the
              // "mastered" meaning; the track is the muted surface behind it.
              color: context.semanticColors.success,
              backgroundColor: context.semanticColors.progressTrack,
            ),
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
  /// [due] and [fresh] are the two pill counts, and they no longer overlap —
  /// `CardListFilter.due` is BR-22's queue minus BR-90's never-reviewed set — so
  /// this line prints them as they arrive. It used to subtract one from the
  /// other, because `due` was the whole queue and one untouched card read as
  /// "1 due · 1 new"; the subtraction moved into the query, where the pills get
  /// it too.
  ///
  /// Three complete sentences rather than one assembled from parts: the
  /// separator, the order and the pluralisation of "due" and "new" all differ
  /// per language, so a `+ ' · ' +` here is untranslatable. Null when neither
  /// number has anything to report — the deck is finished for now, and a line
  /// of zeroes is noise.
  String? _waitingLine(BuildContext context, int due, int fresh) {
    if (due > 0 && fresh > 0) {
      return context.l10n.cardProgressDueNew(due, fresh);
    }
    if (due > 0) return context.l10n.cardProgressDueOnly(due);
    if (fresh > 0) return context.l10n.cardProgressNewOnly(fresh);

    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiet = context.colors.onSurfaceVariant;
    // The two counts the pills already read, said once more where the summary is
    // — "how far along" above, "what is waiting" below it. Null until each lands.
    final due = ref.watch(cardDueCountProvider(deckId)).value;
    final fresh = ref.watch(cardNewCountProvider(deckId)).value;
    final waiting = due == null || fresh == null
        ? null
        : _waitingLine(context, due, fresh);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          context.l10n.cardProgressTitle.toUpperCase(),
          // **`label-md` on `onSurface`, not `label-sm` on the muted colour.**
          // It is the panel's heading and it was set smaller *and* fainter than
          // the line it introduces — 11px at `onSurfaceVariant` above 14px at
          // `onSurface` — so it read as a caption under the ring rather than as
          // the title of the block. Same rung as `YOUR DECKS` on the deck list
          // now, and the same colour as the count it heads.
          //
          // It stays uppercase with the section tracking, which is what keeps it
          // a heading rather than a competing statistic: it is 12 against the
          // count's 14, and it carries no number of its own.
          style: context.texts.labelMedium?.copyWith(
            color: context.colors.onSurface,
            letterSpacing: AppTypography.sectionLabelTracking,
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
            // **`label-md`, not `label-sm` — and the colour deliberately does
            // not move.** The line reads faint, and the obvious fix is to darken
            // it; measured, `onSurfaceVariant` on `surface` is 6.41:1 in light
            // and 7.30:1 in dark, against WCAG's 4.5:1 for body text. It is not
            // a contrast problem, so darkening it would trade a real hierarchy
            // — this sits under the headline, not level with it — for a
            // compliance gain that does not exist.
            //
            // What was actually small is the type: 11px carrying two counts.
            // 12 is the same rung as the heading above and the legend below, so
            // the panel now sets everything except its one headline at label-md.
            style: context.texts.labelMedium?.copyWith(color: quiet),
          ),
        ],
      ],
    );
  }
}
