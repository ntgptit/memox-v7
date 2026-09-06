import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/extensions/app_well_fill.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_empty_state.dart';
import '../../../../../shared/widgets/mx_metric_well.dart';
import '../../../domain/models/study_entry_summary_model.dart';

/// The way into a deck's study flow: two numbers, and up to two ways in.
///
/// **Two numbers, never one** (BR-150). The sets have very different costs — a
/// new card walks five stages, a due one takes a single turn — so a combined
/// total tells the user nothing about what the next ten minutes will be like.
/// Since v5 they are disjoint by shape, which is what lets them be read side by
/// side without either double-counting a card.
///
/// **Nothing due means no way in, and that is a normal screen** (BR-29, BR-145).
/// Studying ahead is a rule rather than a missing feature, so the review button
/// is absent with an explanation rather than present and refusing.
///
/// **Nothing new *and* nothing due is a different face, not this one with its
/// numbers set to zero.** Both entries are gone, so what is left is two loose
/// sentences under a readout row whose largest type spends itself saying
/// "New 0" — the app's loudest element stating an absence. `MxEmptyState` is
/// the face the rest of the app gives a dead end, and like `trash_screen.dart`
/// and `progress_deck_screen.dart` this one carries no action: the way out is
/// the app bar, and a button here would be a second one.
class StudyEntrySectionWidget extends StatelessWidget {
  const StudyEntrySectionWidget({
    required this.summary,
    required this.onLearn,
    required this.onReview,
    super.key,
  });

  final StudyEntrySummaryModel summary;
  final VoidCallback onLearn;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Before the counts row, because at (0, 0) the row is the problem: it is
    // the only thing left at `titleMedium` and it says nothing. Deliberately
    // action-free — see the class doc.
    if (summary.newCount == 0 && summary.dueCount == 0) {
      return MxEmptyState(
        title: l10n.studyEntryAllCaughtUpTitle,
        message: l10n.studyNothingDueMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // **A `Wrap`, because a `Row` of two unconstrained `Text`s cannot
        // break** (SC-C7-05). There was no `Flexible`, no `maxLines` and no
        // second run, so at the size the project promises to fit the pair
        // simply painted overflow stripes across the screen's primary content:
        // measured on this section at `textScaler` 2.0, Vietnamese overflowed
        // by 7.9px at 360dp with three-digit counts, 51px with four, 18px at
        // 393dp and 91px at 320dp. English fits in every one of those cells,
        // which is why nobody saw it — `Mới {count}` and `Đến hạn {count}` are
        // longer than `New` and `Due`, and these counts aggregate a whole deck
        // subtree, so four figures is an ordinary number for somebody who has
        // been away.
        //
        // `lg` keeps the gap the row already had — it is the item gap, and
        // these are two items. The three siblings that solved the same problem
        // reached for `Wrap` too: `study_home_workload_item_widget.dart`,
        // `progress_metric_widget.dart` and `deck_workload_line_widget.dart`.
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            // Plain readouts, not disabled pills. A first draft used
            // `MxPillButton(onPressed: null)` for the shape, and the visual
            // audit refused it: a disabled control renders its label at 38%
            // alpha, which is not a palette colour — and these are readouts,
            // not controls somebody is being stopped from pressing.
            _EntryMetric(
              icon: summary.newCount > 0
                  ? Icons.auto_awesome
                  : Icons.auto_awesome_outlined,
              count: summary.newCount,
              word: l10n.studyEntryNewWord,
              sentence: l10n.studyNewCount(summary.newCount),
              tint: summary.newCount > 0 ? AppInk.info : AppInk.quiet,
              fill: AppWellFill.muted,
            ),
            _EntryMetric(
              icon: summary.dueCount > 0 ? Icons.event : Icons.event_outlined,
              count: summary.dueCount,
              word: l10n.studyEntryDueWord,
              sentence: l10n.studyDueCount(summary.dueCount),
              tint: summary.dueCount > 0 ? AppInk.onDueContainer : AppInk.quiet,
              fill: summary.dueCount > 0 ? AppWellFill.due : AppWellFill.muted,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (summary.newCount > 0)
          MxActionButton(label: l10n.studyStartLearning, onPressed: onLearn)
        else
          Text(l10n.studyNothingNewMessage),
        // `sm`, the gap `study_resume_widget.dart` already stacks these same
        // two labels at. It was `md`, which `app_spacing.dart` reserves for the
        // inside of a compact control — so one dismiss apart, on the same
        // route, `Learn new` and `Review` sat 12 apart here and 8 apart there
        // (SC-C2-12). A stacked action group gets one gap.
        const SizedBox(height: AppSpacing.sm),
        if (summary.dueCount > 0)
          MxActionButton(
            label: l10n.studyStartReview,
            onPressed: onReview,
            variant: MxActionButtonVariant.secondary,
          )
        else
          Text(l10n.studyNothingDueMessage),
      ],
    );
  }
}

/// One count of the entry pair: its glyph in a well, its numeral, its word.
///
/// **The app's metric grammar, which this screen was the last to be outside of**
/// (SC-C9-10). The two counts were undifferentiated `titleMedium` strings —
/// numeral and word at one weight, no anchor — so the pair read as the
/// screen's heading rather than as its data. Every other surface showing the
/// same class of fact gives each count a boundary and steps the word down:
/// `study_home_workload_item_widget.dart`, `progress_metric_widget.dart` and
/// `deck_workload_line_widget.dart`.
///
/// **The numeral stays neutral and only the word takes the tint**, which is
/// that grammar's own rule: tinting both makes the number a colour-coded
/// signal, and two differently-coloured numerals read as two kinds of number
/// rather than two counts of the same kind.
///
/// **The panel rung, not `bodySmall`.** Study Home draws these inside a deck
/// row where they are supporting detail; here they are the screen's only
/// content, so the numeral keeps `titleMedium` — the rung
/// `progress_metric_widget.dart` uses for a panel.
///
/// **Tabular figures, and that is not decoration**: `New 1024` beside
/// `Due 2048` is read as a column of two, and proportional digits put their
/// units in different places.
///
/// **The split is visual only.** A reader hears [sentence] — the whole ARB
/// string, unchanged — because the halves are excluded beneath it: `1024` and
/// `new` announced as two nodes is worse than the one sentence they replace.
class _EntryMetric extends StatelessWidget {
  const _EntryMetric({
    required this.icon,
    required this.count,
    required this.word,
    required this.sentence,
    required this.tint,
    required this.fill,
  });

  final IconData icon;
  final int count;
  final String word;

  /// What a screen reader hears instead of the two halves.
  final String sentence;

  final AppInk tint;
  final AppWellFill fill;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: sentence,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MxMetricWell(icon: icon, tint: tint, fill: fill),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: '$count ',
                      style: context.texts.titleMedium!.inked(
                        context,
                        AppInk.stated,
                        isTabular: true,
                      ),
                    ),
                    TextSpan(
                      text: word,
                      style: context.texts.labelMedium!.inked(
                        context,
                        tint,
                        isEmphasized: count > 0,
                      ),
                    ),
                  ],
                ),
                // Two lines rather than one: a count clipped mid-numeral does
                // not read as truncated, it reads as a different number, and
                // these aggregate a whole deck subtree.
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
