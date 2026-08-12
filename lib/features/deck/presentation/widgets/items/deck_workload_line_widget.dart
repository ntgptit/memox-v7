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
    final hasDue = summary.dueCardCount > 0;
    final hasNew = summary.newCardCount > 0;
    // Composed outside the widget arguments: the count is data and the word
    // comes from the ARB — there is no translatable literal here for the i18n
    // guard to review, and hoisting makes that legible to it.
    final dueLabel =
        '${summary.dueCardCount} ${context.l10n.deckDueMetricWord}';
    final newLabel =
        '${summary.newCardCount} ${context.l10n.deckNewMetricWord}';

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          dueLabel,
          style: context.texts.bodySmall?.copyWith(
            color: hasDue ? semantic.onStreakContainer : quiet,
            fontWeight: hasDue ? FontWeight.w600 : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // The separator travels with the metric it introduces, so a line break
        // can never strand a lone `·`.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('·', style: context.texts.bodySmall?.copyWith(color: quiet)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              newLabel,
              style: context.texts.bodySmall?.copyWith(
                color: hasNew ? semantic.info : quiet,
                fontWeight: hasNew ? FontWeight.w600 : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}
