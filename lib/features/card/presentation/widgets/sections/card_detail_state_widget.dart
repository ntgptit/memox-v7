import 'package:flutter/material.dart';

import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../deck/domain/models/scheduler_type_model.dart';
import '../../../domain/entities/card_study_state_entity.dart';
import '../../../domain/models/card_detail_model.dart';
import '../../../domain/models/card_state_model.dart';
import '../support/card_state_widget.dart';
import '../support/card_tag_chip_widget.dart';

/// The card's marks and its schedule **as it stands now** (BR-183, M4.14 W2
/// band 2).
///
/// **Only the fields of the scheduler this card is actually on.** An
/// `eight_box` card has no ease factor and an `sm2` card has no box (AD-08), so
/// the other algorithm's rows are absent rather than shown empty — a labelled
/// blank invites the reader to look for a value that cannot exist.
///
/// **Nothing here is derived beyond the display state**, which comes from the
/// same `cardStateOf` the list row uses. No accuracy, no streak, no percentage:
/// BR-186 keeps every aggregate on this screen out, because a second definition
/// of a statistic is one that will disagree with the real one.
class CardDetailStateWidget extends StatelessWidget {
  const CardDetailStateWidget({required this.detail, super.key});

  final CardDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = detail.studyState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          l10n.cardDetailStateSectionTitle,
          style: context.texts.titleSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        // Flag, then tags, then the display state, then the schedule — the
        // order W2 band 2 lists, so the wireframe and the screen can be read
        // against each other without translating between two orders.
        if (detail.card.isFlagged) ...<Widget>[
          _FlagRow(label: l10n.cardDetailFlaggedLabel),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (detail.tagNames.isNotEmpty) ...<Widget>[
          _TagRow(names: detail.tagNames, label: l10n.cardDetailTagsLabel),
          const SizedBox(height: AppSpacing.md),
        ],
        _StateRow(state: detail.state),
        const SizedBox(height: AppSpacing.md),
        for (final row in _scheduleRows(context, state))
          _ScheduleRow(label: row.$1, value: row.$2),
      ],
    );
  }

  /// The schedule as label/value pairs, shared plus per-scheduler.
  ///
  /// A list rather than a chain of widgets so every row goes through one
  /// alignment (M4.14 G2) and so which rows exist is one readable expression
  /// instead of a `Column` full of conditionals.
  List<(String, String)> _scheduleRows(
    BuildContext context,
    CardStudyStateEntity state,
  ) {
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

    return <(String, String)>[
      (l10n.cardDetailDueLabel, date(state.dueAt, whenNull: unscheduled)),
      (
        l10n.cardDetailLearnedLabel,
        date(state.learnedAt, whenNull: unscheduled),
      ),
      (
        l10n.cardDetailLastAnsweredLabel,
        date(
          state.lastAnsweredAt,
          whenNull: l10n.cardDetailNeverAnsweredValue,
        ),
      ),
      (l10n.cardDetailReviewsLabel, '${state.answerCount}'),
      (l10n.cardDetailLapsesLabel, '${state.lapseCount}'),
      if (state.schedulerType == SchedulerType.eightBox &&
          state.currentBox != null)
        (l10n.cardDetailBoxLabel, '${state.currentBox}'),
      if (state.schedulerType == SchedulerType.sm2) ...<(String, String)>[
        if (state.easeFactor != null)
          (l10n.cardDetailEaseLabel, state.easeFactor!.toStringAsFixed(2)),
        if (state.intervalDays != null)
          (
            l10n.cardDetailIntervalLabel,
            l10n.cardDetailDayCount(state.intervalDays!),
          ),
        if (state.repetitions != null)
          (l10n.cardDetailRepetitionsLabel, '${state.repetitions}'),
      ],
    ];
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
          style: context.texts.bodyMedium?.copyWith(
            color: context.colors.onSurface,
          ),
        ),
      ],
    );
  }
}

/// The user's flag, present only when set — the detail screen shows it and
/// never toggles it (BR-92, BR-182).
class _FlagRow extends StatelessWidget {
  const _FlagRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(
          Icons.flag,
          size: AppIconSize.sm,
          // `onSurface`, not `primary`: the accent measures 3.29:1 as a glyph
          // on the dark surface, below what a painted mark needs. The flag
          // reads by shape; the colour only stays legible.
          color: context.colors.onSurface,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: context.texts.bodyMedium),
      ],
    );
  }
}

/// The read-only chip strip (BR-93), wrapping so ten tags reflow at 320dp
/// instead of overflowing.
class _TagRow extends StatelessWidget {
  const _TagRow({required this.names, required this.label});

  final List<String> names;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: context.texts.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (final name in names) CardTagChipWidget(name: name),
          ],
        ),
      ],
    );
  }
}

/// One label/value pair of the schedule.
///
/// **Two columns, and the label column is fixed**, so every value starts at the
/// same x (M4.14 G2) instead of being pushed around by the length of the word
/// beside it. The column scales with the text, because a constant dp would clip
/// the longest label in either language at 2.0 — and Vietnamese runs longer
/// than English here.
///
/// **Past a point the two columns stop fitting, and then it stacks.** At 320dp
/// with a 2.0 scaler the label column alone is 232 of the 288 available, which
/// leaves 44 for the value — less than one word of `bodySmall` at that scale.
/// Nothing overflows and nothing throws, so the failure is silent: the value
/// simply lays out past its column. Below the threshold the row becomes the
/// same label-over-value shape the content band already uses, which keeps the
/// value readable at the cost of G2's alignment — an alignment nobody can read
/// when the text it aligns is cut off.
class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelWidth = MediaQuery.textScalerOf(
            context,
          ).scale(_labelColumnWidth);
          final fitsBeside =
              labelWidth + AppSpacing.md <=
              constraints.maxWidth * _maxLabelColumnFraction;

          return fitsBeside
              ? _SideBySide(label: label, value: value, labelWidth: labelWidth)
              : _Stacked(label: label, value: value);
        },
      ),
    );
  }
}

/// The two-column form, which is what G2 measures.
class _SideBySide extends StatelessWidget {
  const _SideBySide({
    required this.label,
    required this.value,
    required this.labelWidth,
  });

  final String label;
  final String value;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(value, style: context.texts.bodySmall)),
      ],
    );
  }
}

/// The narrow form: label over value, both on the band's left edge.
class _Stacked extends StatelessWidget {
  const _Stacked({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: context.texts.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        Text(value, style: context.texts.bodySmall),
      ],
    );
  }
}

/// The state dot's diameter, matching the list row's — colour and position
/// carry it, not size.
const double _stateDotSize = 10;

/// The unscaled width of the schedule's label column, sized to the longest
/// label in either language at 1.0×.
const double _labelColumnWidth = 116;

/// How much of the row the scaled label column may take before the pair stacks.
///
/// Not a design value and deliberately not a token: it is this grid's own
/// layout rule. Past 45% the remainder stops being able to hold one word of
/// `bodySmall` at the scale that got it there, and a value laid out past its
/// column is worse than a taller row.
const double _maxLabelColumnFraction = 0.45;
