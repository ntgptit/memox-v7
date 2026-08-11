import 'package:flutter/material.dart';

import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/deck_summary_model.dart';

/// The deck's workload, stated in full: `7 Due · 14 New` (BR-150, BR-142).
///
/// **Both numbers, always — zero included.** An absent metric is ambiguous in
/// exactly the way this line exists to prevent: "no due chip" could mean zero
/// due or could mean the screen only tracks new, and a reader should never
/// have to know the convention to read the card. `0 Due · 14 New` says which.
///
/// **The words are the signal; colour only supports.** In grayscale the line
/// still reads completely, because each metric carries its own word. Due leads
/// and is the emphasized one — it expires, new does not — carried on
/// `streakContainer` with a clock, which is the time-pressure role and
/// deliberately not `danger`: a review coming due is the product working,
/// not an error (BR-29). New is a quiet text metric in `info` ink; a zero on
/// either side steps down to the neutral variant so nothing shouts about
/// nothing.
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
      return _WorkloadBox(
        child: Text(
          context.l10n.deckNoCardsLabel,
          style: context.texts.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final quiet = context.colors.onSurfaceVariant;

    return _WorkloadBox(
      // A Wrap rather than a Row: at text scale 2.0 on a 320 screen the two
      // metrics break onto their own lines instead of clipping.
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _DueMetric(count: summary.dueCardCount),
          Text('·', style: context.texts.labelMedium?.copyWith(color: quiet)),
          _NewMetric(count: summary.newCardCount),
        ],
      ),
    );
  }
}

/// Due first, and louder — but only when it is non-zero.
///
/// A filled chip around a zero would spend the screen's one time-pressure
/// colour saying nothing is pressing; the zero keeps its place in the line and
/// steps down to the neutral ink instead.
class _DueMetric extends StatelessWidget {
  const _DueMetric({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final text = '$count ${context.l10n.deckDueMetricWord}';

    if (count == 0) {
      return Text(
        text,
        style: context.texts.labelMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: semantic.streakContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.schedule,
              size: AppIconSize.sm,
              color: semantic.onStreakContainer,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              text,
              style: context.texts.labelMedium?.copyWith(
                color: semantic.onStreakContainer,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// New, second and quieter: a text metric, never a filled container.
///
/// `info` measured 5.23:1 on the light surface and 7.84:1 on the dark one
/// (`deck_workload_role_test.dart` holds the pair), so the ink carries body
/// text in both themes. Zero steps down to the neutral variant.
class _NewMetric extends StatelessWidget {
  const _NewMetric({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Text(
    '$count ${context.l10n.deckNewMetricWord}',
    style: context.texts.labelMedium?.copyWith(
      color: count == 0
          ? context.colors.onSurfaceVariant
          : context.semanticColors.info,
      fontWeight: count == 0 ? null : FontWeight.w600,
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

/// One floor for every resting state, so a card whose due count happens to be
/// zero does not sit 8px shorter than its neighbour with a chip.
///
/// A minimum, not a fixed height: the Wrap above needs room to break at large
/// text scales.
class _WorkloadBox extends StatelessWidget {
  const _WorkloadBox({required this.child});

  final Widget child;

  /// The chip's own height — a `label-md` line plus `xs` above and below.
  static const double _floor = 24;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: _floor),
    alignment: AlignmentDirectional.centerStart,
    child: child,
  );
}
