import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/typography/app_typography.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_metric_well.dart';
import '../../../domain/models/progress_overview_model.dart';
import '../support/progress_labels_widget.dart';
import '../../../../../core/theme/extensions/app_well_fill.dart';

/// The hero: how many days in a row, and what today looks like (W2, visual
/// revision 2026-08-28).
///
/// **One semantics node for the whole panel.** Read as separate nodes, a screen
/// reader announces "7", "days", "3 cards today" — three fragments in which the
/// figure has lost what it measures. `MergeSemantics` would concatenate the
/// visible text; an explicit label lets the announcement say "Current streak, 7
/// days" without putting that phrasing on screen, where the section heading
/// already says it.
///
/// **The second clause is the visible supporting line, not a rebuild of it from
/// counts.** The line has three shapes and only one of them is "n cards today";
/// a label built from `(streak, todayTotal)` therefore announced a bare "No
/// cards today" under a headline of "6 days" — the contradiction W2.5 exists to
/// remove — and dropped P6's invitation entirely at streak zero. Reusing
/// [ProgressLabelsX.progressStreakSupportLine] is what keeps the two in step:
/// there is one sentence, and the eye and the screen reader get the same one.
class ProgressStreakHeroWidget extends StatelessWidget {
  const ProgressStreakHeroWidget({required this.overview, super.key});

  final ProgressOverview overview;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;
    final hasStreak = overview.currentStreakDays > 0;

    return Semantics(
      container: true,
      label: context.l10n.progressStreakSemantics(
        context.l10n.progressStreakSemanticsHeadline(
          overview.currentStreakDays,
        ),
        context.progressStreakSupportLine(overview),
      ),
      child: ExcludeSemantics(
        // Flat, like every other card in a scrolling column (M99.26): two
        // competing depths in one column is what makes a list read as busy,
        // which is the reason the deck tile and the Study Home row already
        // gave. Progress was the only surface still taking the default.
        child: MxCard.raised(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.l10n.progressStreakSectionLabel,
                style: texts.labelLarge!.inked(context, AppInk.quiet),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // A well, not a bare figure — the same grammar every metric
                  // in the app anchors on (`MxMetricWell`), so the streak reads
                  // as a measured fact rather than as the poster the display
                  // rung used to make it. The tint pair is the app's existing
                  // streak vocabulary — `streakContainer`/`onDueContainer` when
                  // there is one to show, `surfaceMuted`/quiet when there is
                  // not — the same pair `_ActiveDaysMetric` already wears for
                  // "time kept" (`progress_metric_widget.dart`), so a zero
                  // streak reads as *neutral*, not as a smaller version of the
                  // same accent that marks an active one.
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: MxMetricWell(
                      icon: Icons.local_fire_department_outlined,
                      tint: hasStreak ? AppInk.onDueContainer : AppInk.quiet,
                      fill: hasStreak ? AppWellFill.streak : AppWellFill.muted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      context.l10n.progressStreakDaysLabel(
                        overview.currentStreakDays,
                      ),
                      // `headlineMedium`, not `displayLarge`: the hero led the
                      // first viewport at a size nothing else on the screen
                      // could balance against (implementation prompt, Why 1).
                      // No text-scaler clamp is needed at this rung — measured
                      // below, not assumed: at scale 2.0 "days" alone is 130dp
                      // in English and 133dp in Vietnamese (28px vs the old
                      // 57px rung, same font), well inside the 264dp compact
                      // content column the old clamp was written for
                      // (`progress_screen_geometry_extremes_test.dart` pins
                      // the absence of clipping instead of a size cap).
                      // Explicit, not left to `Text`'s own default — the
                      // property the extremes test reads off the render
                      // object is only populated once something states it.
                      textScaler: MediaQuery.textScalerOf(context),
                      // The one weight a feature adds, by its name: the hero
                      // numeral's (A20.1 P1-10).
                      style: AppTypography.withWeight(
                        texts.headlineMedium!,
                        AppTypography.heroNumeralWeight,
                      ).inked(context, AppInk.stated),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.progressStreakSupportLine(overview),
                style: texts.bodyMedium!.inked(context, AppInk.quiet),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
