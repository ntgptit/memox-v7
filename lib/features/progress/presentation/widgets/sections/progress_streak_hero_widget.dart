import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/progress_overview_model.dart';
import '../support/progress_labels_widget.dart';

/// The hero: how many days in a row, and what today looks like (W2).
///
/// **One semantics node for the whole panel.** Read as separate nodes, a screen
/// reader announces "7", "days", "3 cards today" — three fragments in which the
/// figure has lost what it measures. `MergeSemantics` would concatenate the
/// visible text; an explicit label lets the announcement say "Current streak, 7
/// days" without putting that phrasing on screen, where the section heading
/// already says it.
class ProgressStreakHeroWidget extends StatelessWidget {
  const ProgressStreakHeroWidget({required this.overview, super.key});

  final ProgressOverview overview;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;
    final colors = context.colors;

    return Semantics(
      container: true,
      label: context.l10n.progressStreakSemantics(
        overview.currentStreakDays,
        overview.today.totalCards,
      ),
      child: ExcludeSemantics(
        child: MxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.l10n.progressStreakSectionLabel,
                style: texts.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.progressStreakDaysLabel(
                  overview.currentStreakDays,
                ),
                // `displayLarge` wraps rather than shrinks: at 320dp with a text
                // scale of 2.0 "14 days" needs two lines, and W6 forbids buying
                // one line back by reducing the type.
                style: texts.displayLarge?.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.progressStreakSupportLine(overview),
                style: texts.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
