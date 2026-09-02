import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/deck_activity_snapshot_model.dart';
import '../../../domain/models/progress_range_model.dart';
import '../items/progress_metric_widget.dart';
import '../support/progress_labels_widget.dart';

/// What the whole level amounts to in the selected window.
///
/// **Read from the snapshot, never folded from the rows.** Active cards and
/// card-days would fold correctly — sibling subtrees are disjoint — but active
/// *days* would not: the same Tuesday can be active in two decks and is one day
/// of study, so a fold would print a number nobody had. All four come from the
/// same statement as the rows, so this panel and the list below it can never
/// disagree (AD-13, BR-183).
///
/// The heading states the window in words. The pills above already say it, but a
/// screenshot of the panel alone, and a screen reader that has moved past the
/// selector, both need the figures to carry their own scope.
class ProgressSummaryWidget extends StatelessWidget {
  const ProgressSummaryWidget({
    required this.snapshot,
    required this.range,
    super.key,
  });

  final DeckActivitySnapshot snapshot;
  final ProgressRange range;

  @override
  Widget build(BuildContext context) {
    // Flat, like every other card in a scrolling column (M99.26): two
    // competing depths in one column is what makes a list read as busy,
    // which is the reason the deck tile and the Study Home row already
    // gave. Progress was the only surface still taking the default.
    return MxCard.raised(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.progressSummaryTitle(range),
            // `labelLarge`, the role its three sibling card headings already
            // use (M99.26). `titleSmall` resolves to the same Inter w600 14/20
            // today, so nothing moves — which is exactly why it was worth
            // fixing now: the day one of the two roles is retuned, two adjacent
            // headings on one screen would change apart.
            style: context.texts.labelLarge!.inked(context, AppInk.quiet),
          ),
          const SizedBox(height: AppSpacing.md),
          ProgressMetricGridWidget(
            metrics: snapshot.scopeMetricsFor(range),
            scale: ProgressMetricScale.panel,
          ),
          const SizedBox(height: AppSpacing.md),
          // **The unit, once, where the total is.** The top row of the grid
          // counts cards and days; the bottom row counts card-days, and without
          // this line `12` and `60` beside `45` read as arithmetic that does not
          // add up. It sits here rather than in the four words because a word
          // long enough to carry the unit is clipped in a 320dp cell at text
          // scale 2.0 — see `ProgressMetricGridWidget.minimumCellWidth`.
          Text(
            context.l10n.progressCardDayUnitNote,
            style: context.texts.bodySmall!.inked(context, AppInk.quiet),
          ),
          if (!snapshot.hasActivityIn(range)) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _NoActivityNote(),
          ],
        ],
      ),
    );
  }
}

/// What four zeroes mean, in words.
///
/// **Inside the panel rather than instead of the list.** Replacing the rows with
/// an empty state was the first shape and it was wrong: a level with nothing
/// studied still has decks, and "which decks did I neglect" is exactly the
/// question a person asks in that state — so the rows stay, each showing its own
/// zeroes (BR-187), and the explanation sits with the total it explains.
///
/// **Neutral, never a warning.** A quiet week is a normal reading, not a fault,
/// so this uses the same `onSurfaceVariant` as any other supporting line: no
/// error role, no icon, no colour that would make the screen scold.
class _NoActivityNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          context.l10n.progressNoActivityTitle,
          style: context.texts.bodyMedium!.inked(context, AppInk.stated),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.progressNoActivityMessage,
          style: context.texts.bodySmall!.inked(context, AppInk.quiet),
        ),
      ],
    );
  }
}
