import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../deck/domain/models/scheduler_type_model.dart';
import '../../../domain/entities/card_study_state_entity.dart';
import '../../../domain/models/card_detail_model.dart';
import '../../../domain/models/card_state_model.dart';
import '../items/card_box_progress_widget.dart';
import '../items/card_metric_widget.dart';
import '../support/card_action_tone_widget.dart';
import '../support/card_state_widget.dart';
import '../../../../../shared/widgets/mx_section_label.dart';

/// Where the scheduler has this card right now (BR-240, M4.15 W2 band 2).
///
/// **Only the fields of the scheduler this card is actually on.** An
/// `eight_box` card has no ease factor and an `sm2` card has no box (AD-08), so
/// the other algorithm's rows are absent rather than shown empty — a labelled
/// blank invites the reader to look for a value that cannot exist. The same rule
/// governs the track above the grid: `eight_box` has eight steps to be on, SM-2
/// has none, and drawing one for it would be inventing a progress metric the
/// algorithm does not define (BR-243).
///
/// **Nothing here is derived beyond the display state**, which comes from the
/// same `cardStateOf` the list row uses. No accuracy, no recall rate, no streak,
/// no "since added": BR-243 keeps every aggregate off this screen, because a
/// second definition of a statistic is one that will disagree with the real one.
class CardDetailStateWidget extends StatelessWidget {
  const CardDetailStateWidget({required this.detail, super.key});

  final CardDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final state = detail.studyState;
    final box = state.currentBox;
    final isBoxed =
        state.schedulerType == SchedulerType.eightBox && box != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Upper-cased with the section tracking, the same heading shape the
        // deck list, the progress panel and the session bar already use — so a
        // reader meets one kind of group title in this app rather than four.
        MxSectionLabel(label: context.l10n.cardDetailStateSectionTitle),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: MxCard.raised(
            // Flat, like every other card in this column (D20): two competing
            // depths in one scroll view read as a rendering fault rather than as
            // a hierarchy. The hairline and the surface step do the separating.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _StateRow(state: detail.state),
                if (isBoxed) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _BoxProgress(currentBox: box),
                ],
                const SizedBox(height: AppSpacing.lg),
                _MetricGrid(metrics: _metrics(context, state)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The schedule as typed cells, shared plus per-scheduler.
  ///
  /// **Typed, so the grid never has to read a label to decide how to draw a
  /// value.** The first version of this screen returned `(String, String)`
  /// pairs, and the only way to accent the box from there was to compare the
  /// label against the localized word `Box` — correct in English, wrong in
  /// Vietnamese, and wrong in silence.
  List<CardMetric> _metrics(BuildContext context, CardStudyStateEntity state) {
    final l10n = context.l10n;
    // `learned_at` and `due_at` travel together (BR-149), so one placeholder
    // answers both and the pair can never say two different things about
    // whether the card has a schedule at all.
    //
    // **`last_answered_at` does not travel with them, so it gets its own
    // word.** A card can have been answered and hold no schedule; "Not
    // scheduled yet" under "Last answered" answered a question nobody asked.
    String date(DateTime? value, {required String whenNull}) => value == null
        ? whenNull
        : MaterialLocalizations.of(context).formatMediumDate(value.toLocal());

    final unscheduled = l10n.cardDetailNotScheduledValue;

    return <CardMetric>[
      CardMetric.date(
        l10n.cardDetailDueLabel,
        date(state.dueAt, whenNull: unscheduled),
        Icons.schedule_rounded,
      ),
      CardMetric.date(
        l10n.cardDetailLearnedLabel,
        date(state.learnedAt, whenNull: unscheduled),
        Icons.school_outlined,
      ),
      CardMetric.date(
        l10n.cardDetailLastAnsweredLabel,
        date(state.lastAnsweredAt, whenNull: l10n.cardDetailNeverAnsweredValue),
        Icons.history_rounded,
      ),
      CardMetric.numeric(
        l10n.cardDetailReviewsLabel,
        '${state.answerCount}',
        Icons.autorenew_rounded,
      ),
      CardMetric.numeric(
        l10n.cardDetailLapsesLabel,
        '${state.lapseCount}',
        Icons.replay_rounded,
      ),
      if (state.schedulerType == SchedulerType.sm2) ...<CardMetric>[
        if (state.easeFactor != null)
          CardMetric.numeric(
            l10n.cardDetailEaseLabel,
            state.easeFactor!.toStringAsFixed(2),
            Icons.speed_rounded,
          ),
        if (state.intervalDays != null)
          CardMetric.numeric(
            l10n.cardDetailIntervalLabel,
            l10n.cardDetailDayCount(state.intervalDays!),
            Icons.event_repeat_rounded,
          ),
        if (state.repetitions != null)
          CardMetric.numeric(
            l10n.cardDetailRepetitionsLabel,
            '${state.repetitions}',
            Icons.repeat_one_rounded,
          ),
      ],
    ];
  }
}

/// The eight-step ladder, with the position stated in words above it.
///
/// **One semantics node, and it says the number.** The track itself is eight
/// coloured boxes — nothing a screen reader can make a sentence out of — so the
/// row and the track are announced together as the position they jointly mean,
/// and the decorative halves are excluded rather than read out one by one.
class _BoxProgress extends StatelessWidget {
  const _BoxProgress({required this.currentBox});

  final int currentBox;

  @override
  Widget build(BuildContext context) {
    final maxBox = context.cardMaxBox;
    final label = context.l10n.cardDetailBoxLabel;
    // Punctuation on screen, words in the ear: `3 / 8` is read as silence or as
    // "slash", so the spoken form is its own ARB key — the one string this
    // presentation-only change adds, and it adds no copy anybody sees.
    final position = '$currentBox / $maxBox';

    return Semantics(
      container: true,
      label: context.l10n.cardDetailBoxPositionSemantics(currentBox, maxBox),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(label, style: cardMetricLabelStyle(context)),
                ),
                Text(
                  position,
                  style: cardMetricValueStyle(
                    context,
                    CardMetricKind.schedulerProgress,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            CardBoxProgressWidget(currentBox: currentBox, maxBox: maxBox),
          ],
        ),
      ),
    );
  }
}

/// The schedule's cells, two across where two fit.
///
/// **The decision is made once for the whole grid, from real constraints.** Two
/// cells that each measured their own width would be free to disagree the moment
/// one of them wrapped, and a per-device breakpoint would be a number chosen
/// against a phone rather than against the text it has to hold. The floor scales
/// with the text scaler because that is what actually makes a cell too narrow.
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<CardMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final floor = MediaQuery.textScalerOf(context).scale(_minCellWidth);
        final columns = (constraints.maxWidth - AppSpacing.md) / 2 >= floor
            ? 2
            : 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var start = 0; start < metrics.length; start += columns) ...[
              if (start > 0) const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (var column = 0; column < columns; column++) ...<Widget>[
                    if (column > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: start + column < metrics.length
                          // The trailing gap of an odd row is an empty cell
                          // rather than a shorter row, so the column edges hold
                          // all the way down.
                          ? CardMetricWidget(metric: metrics[start + column])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The display state, drawn exactly as the list row draws it: a coloured dot
/// beside the word, so colour is never the only signal (D5).
class _StateRow extends StatelessWidget {
  const _StateRow({required this.state});

  final CardState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: _stateDotSize,
          height: _stateDotSize,
          decoration: BoxDecoration(
            color: context.cardStateColor(state),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          context.cardStateLabel(state),
          style: context.texts.bodyMedium!.inked(context, AppInk.stated),
        ),
      ],
    );
  }
}

/// The state dot's diameter, matching the list row's — colour and position
/// carry it, not size.
// off-grid: matches the list row's dot for the same reason it has
const double _stateDotSize = 10;

/// The narrowest a cell may be before the grid drops to one column.
///
/// Not a design value and deliberately not a token: it is this grid's own layout
/// rule — a 32dp well, its `sm` gap and roughly six characters of `bodyMedium`.
/// Below it the value wraps mid-word while the label still fits, which is the
/// shape that reads as a rendering fault rather than as a narrow screen.
const double _minCellWidth = 132;
