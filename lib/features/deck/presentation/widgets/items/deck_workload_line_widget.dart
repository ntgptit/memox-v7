import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
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
        style: context.texts.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final semantic = context.semanticColors;
    final quiet = context.colors.onSurfaceVariant;
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

    Widget fact(String label, {Color? ink, bool isBold = false}) => Text(
      label,
      style: context.texts.bodySmall?.copyWith(
        color: ink ?? quiet,
        fontWeight: isBold ? FontWeight.w600 : null,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    // The separator travels with the metric it introduces, so a line break
    // can never strand a lone `·`.
    Widget joined(Widget child) => Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('·', style: context.texts.bodySmall?.copyWith(color: quiet)),
        const SizedBox(width: AppSpacing.xs),
        child,
      ],
    );

    final parts = <Widget>[
      if (overdueCount > 0)
        fact(overdueLabel, ink: semantic.danger, isBold: true),
      if (hasDue) fact(dueLabel, ink: semantic.onStreakContainer, isBold: true),
      if (hasNew) fact(newLabel, ink: semantic.info, isBold: true),
    ];
    // A filled deck with nothing pending still states both zeroes: an absent
    // metric is ambiguous in exactly the way this line exists to prevent.
    if (parts.isEmpty) {
      parts.addAll(<Widget>[fact(dueLabel), fact(newLabel)]);
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (final (index, part) in parts.indexed)
          index == 0 ? part : joined(part),
      ],
    );
  }
}
