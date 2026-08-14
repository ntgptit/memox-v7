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
    final colors = context.colors;

    return Semantics(
      container: true,
      label: context.l10n.progressStreakSemantics(
        context.l10n.progressStreakSemanticsHeadline(
          overview.currentStreakDays,
        ),
        context.progressStreakSupportLine(overview),
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
                // **The one place in this app that caps the text scaler, and it
                // is not to buy back a line** (X6).
                //
                // `displayLarge` is 57px, so at a 2.0 scale the *unit word on
                // its own* measures 268.1dp in English and 274.9dp in Vietnamese
                // against a content column of `320 − 2×12 − 2×16 = 264dp`.
                // Wrapping cannot help: there is no break opportunity inside
                // "days", so the engine breaks mid-word and renders `5` / `day`
                // / `s`. That is not one line too many, it is a word cut in
                // half — W6.1 forbids clipping and this is worse, because it
                // looks deliberate.
                //
                // 1.75 is the largest cap that fits both locales (234.6dp EN,
                // 240.5dp VI), measured rather than picked, and it changes
                // nothing below it: every viewport at a scale ≤ 1.75 renders
                // exactly as before. Applied to this `Text` alone — the two
                // other lines in the card, and every other section, keep the
                // user's full setting.
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.75),
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
