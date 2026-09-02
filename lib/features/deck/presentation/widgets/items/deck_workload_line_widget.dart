import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_radius.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/deck_summary_model.dart';

/// The deck's workload, stated in full: `12 Due · 46 New` (BR-150, BR-142).
///
/// **Both numbers, always — zero included.** An absent metric is ambiguous in
/// exactly the way this line exists to prevent: "no due count" could mean zero
/// due or could mean the screen only tracks new, and a reader should never
/// have to know the convention to read the card. `0 Due · 14 New` says which.
///
/// **Plain text, one typography, ink as the only state.** The icon-per-metric
/// experiment put five visual anchors on a three-line block and the golden
/// showed the cost: metadata wrapped, cards grew, hierarchy flattened. The
/// schedule urgency the small clock used to carry moved up to the large
/// status icon (BR-161), so this line is back to what it says: two counts,
/// due first, `Due`/`New` as the non-colour signal. A positive due count
/// wears the time-pressure ink — never `danger`, a review coming due is the
/// product working (BR-29) — a positive new count wears `info`, and zeroes
/// rest on the neutral variant.
///
/// A deck with no cards at all has no workload to misreport, and says
/// "No cards" instead — a different fact from `0 Due · 0 New`, which is a
/// filled deck with nothing pending (UC-06).
class DeckWorkloadLineWidget extends StatelessWidget {
  const DeckWorkloadLineWidget({required this.summary, super.key});

  final DeckSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.totalCardCount == 0) {
      return Text(
        context.l10n.deckNoCardsLabel,
        style: context.texts.bodySmall!.inked(context, AppInk.quiet),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final semantic = context.semanticColors;
    final overdueCount = summary.overdueCardCount;
    final dueTodayCount = summary.dueCardCount - overdueCount;
    final hasDue = dueTodayCount > 0;
    final hasNew = summary.newCardCount > 0;
    // **Overdue is its own count now** (owner mockup, 2026-08-20): it used to
    // ride the icon as a `+7d` badge, which said how *old* the backlog was
    // but not how *big* — and the tile said "12 due" for a deck where eight
    // of the twelve had already missed their day. The three disjoint counts
    // read in urgency order, overdue in the one semantic ink left on the
    // card.
    final overdueLabel = context.l10n.deckSummaryOverduePart(overdueCount);
    final dueLabel = context.l10n.deckTileDueChipLabel(dueTodayCount);
    final newLabel = context.l10n.deckTileNewChipLabel(summary.newCardCount);

    final parts = <Widget>[
      if (overdueCount > 0)
        _WorkloadChip(
          label: overdueLabel,
          // `dangerContainer`, which *is* `errorContainer` — one red system.
          // The name is the fix: a review past its day is late, not a fault
          // (M100.21).
          fill: semantic.dangerContainer,
          ink: AppInk.onDangerContainer,
        ),
      if (hasDue)
        _WorkloadChip(
          label: dueLabel,
          fill: semantic.dueContainer,
          ink: AppInk.onDueContainer,
        ),
      if (hasNew)
        _WorkloadChip(
          label: newLabel,
          fill: semantic.surfaceMuted,
          ink: AppInk.quiet,
        ),
    ];
    // **Nothing pending says so once** (owner review, 2026-08-21). It used to
    // print `0 due · 0 new`, on the argument that an absent metric is
    // ambiguous — but two chips of zero are two facts about what is *not*
    // there, and a reader scanning for work has to read both to learn
    // nothing. One chip states the whole state instead.
    //
    // No verb goes with it: BR-145 forbids opening a review before anything
    // is due, so a `Practice` button here would be an action that cannot run
    // (owner decision, 2026-08-21).
    if (parts.isEmpty) {
      parts.add(
        _WorkloadChip(
          label: context.l10n.deckTileAllCaughtUpLabel,
          fill: semantic.surfaceMuted,
          ink: AppInk.quiet,
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: parts,
    );
  }
}

/// One count on its own tinted ground.
///
/// **Chips, not coloured words** (owner review, 2026-08-20). The three counts
/// were ink on the card surface separated by middle dots, which read as one
/// multicoloured sentence — the eye had to parse the line before it could
/// find the number that mattered. A chip gives each count a boundary, so the
/// row scans as three facts.
///
/// Every pair is a container pair, so the ink is legible on its own ground by
/// construction: `errorContainer` for the backlog, the due pair for
/// today's reviews, and `surfaceMuted` for new — new is **not** a warning, and
/// the blue it used to wear was the only place in the app where a metric read
/// as a link.
class _WorkloadChip extends StatelessWidget {
  const _WorkloadChip({
    required this.label,
    required this.fill,
    required this.ink,
  });

  final String label;
  final Color fill;
  final AppInk ink;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: context.texts.bodySmall!.inked(
            context,
            ink,
            isEmphasized: true,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
