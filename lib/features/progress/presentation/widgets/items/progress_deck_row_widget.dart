import 'package:flutter/material.dart';

import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/deck_activity_model.dart';
import '../../../domain/models/progress_range_model.dart';
import '../support/progress_labels_widget.dart';
import 'progress_metric_widget.dart';

/// One deck on the Progress by Deck list: what it is, where it sits, and what it
/// amounts to in the selected window.
///
/// **The whole card is the target** (`MxCard.onTap`), rather than a chevron
/// button at the end. A row that stands for a place you can open should open it
/// wherever you press; a small trailing control leaves the rest of the row
/// looking tappable and inert. The chevron stays as the *affordance* — it says
/// there is somewhere to go — and takes no gesture of its own.
///
/// **The path is on the row, not in a breadcrumb above the list.** Two decks
/// called `Verbs` under two different roots are one screenshot apart otherwise,
/// and the row is also what a screen reader reads: `Verbs, in Spanish › Grammar`
/// is a complete answer where `Verbs` is not.
///
/// **Zero activity still renders.** A deck nobody touched is exactly what
/// somebody scrolling this list is looking for, and hiding it would answer
/// "which decks have I neglected" by removing the answer (BR-187).
class ProgressDeckRowWidget extends StatelessWidget {
  const ProgressDeckRowWidget({
    required this.activity,
    required this.range,
    required this.onOpen,
    super.key,
  });

  final DeckActivity activity;
  final ProgressRange range;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final path = context.progressPathLabel(activity.path);

    // Flat, like every other card in a scrolling column (M99.26): two
    // competing depths in one column is what makes a list read as busy,
    // which is the reason the deck tile and the Study Home row already
    // gave. Progress was the only surface still taking the default.
    return MxCard(
      elevation: AppElevation.none,
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Semantics(
                  // **No `container`, so this sentence names the card's own
                  // button node** rather than hanging beside it. With one, the
                  // tappable node had `isButton` and no label at all — a reader
                  // focusing the row heard "button" and nothing else, and the
                  // name arrived on a separate node they had to swipe to.
                  // `labelledTapTargetGuideline` on the composed screen is what
                  // caught it; the row's own tests could not, because they
                  // asserted the label exists somewhere, which it did.
                  //
                  // **The window rides on the row, and only on the row.** The
                  // summary panel states it in words, but a reader swiping into
                  // the middle of fifty decks never passes the panel — and
                  // repeating it on each of the four metrics instead would say
                  // it four times per row. A root deck has no path, and a
                  // sentence with an empty clause reads worse than the name
                  // alone, so it gets the two-part variant.
                  label: path.isEmpty
                      ? context.l10n.progressDeckRootRowSemanticLabel(
                          activity.name,
                          context.progressRangeSemanticLabel(range),
                        )
                      : context.l10n.progressDeckRowSemanticLabel(
                          activity.name,
                          path,
                          context.progressRangeSemanticLabel(range),
                        ),
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          activity.name,
                          style: context.texts.titleMedium?.copyWith(
                            color: context.colors.onSurface,
                          ),
                        ),
                        if (path.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          // Wraps rather than ellipsizes: a path truncated in
                          // the middle stops telling two same-named decks
                          // apart, which is the only reason it is here.
                          Text(
                            path,
                            style: context.texts.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Decorative: the card's own tap action is what a screen reader
              // announces, and a chevron with a label would be read as a second
              // control that does not exist.
              ExcludeSemantics(
                child: Icon(
                  Icons.chevron_right,
                  size: AppIconSize.md,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ProgressMetricGridWidget(
            metrics: activity.metricsFor(range),
            scale: ProgressMetricScale.row,
          ),
        ],
      ),
    );
  }
}
