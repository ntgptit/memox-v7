import 'package:flutter/material.dart';

import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../deck/domain/models/scheduler_type_model.dart';
import '../../../domain/entities/card_study_state_entity.dart';
import '../../../domain/models/card_detail_model.dart';
import '../../../domain/models/card_state_model.dart';
import '../support/card_state_widget.dart';
import '../support/card_tag_chip_widget.dart';

/// The card's marks and its schedule **as it stands now** (BR-240, M4.15 W2
/// band 2).
///
/// **Three blocks, not eleven lines.** The marks are a chip row, the tags are a
/// chip row, and the schedule is an inset panel on `surfaceMuted` — so the band
/// says "these are labels on the card" and "this is its arithmetic" by shape,
/// which it previously said only by the order the lines happened to be in.
///
/// **Only the fields of the scheduler this card is actually on.** An
/// `eight_box` card has no ease factor and an `sm2` card has no box (AD-08), so
/// the other algorithm's rows are absent rather than shown empty — a labelled
/// blank invites the reader to look for a value that cannot exist.
///
/// **Nothing here is derived beyond the display state**, which comes from the
/// same `cardStateOf` the list row uses. No accuracy, no streak, no percentage:
/// BR-243 keeps every aggregate on this screen out, because a second definition
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
        _SectionHeader(label: l10n.cardDetailStateSectionTitle),
        // The display state and the flag are both *marks on this card*, so they
        // share a row and wrap together rather than the flag opening a line of
        // its own above them (M4.15 W2 band 2 lists them in this order, which
        // the row preserves left to right).
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            _StateChip(state: detail.state),
            if (detail.card.isFlagged)
              _FlagChip(label: l10n.cardDetailFlaggedLabel),
          ],
        ),
        if (detail.tagNames.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _TagRow(names: detail.tagNames, label: l10n.cardDetailTagsLabel),
        ],
        const SizedBox(height: AppSpacing.lg),
        _SchedulePanel(rows: _scheduleRows(context, state)),
      ],
    );
  }

  /// The schedule as label/value pairs, shared plus per-scheduler.
  ///
  /// A list rather than a chain of widgets so every row goes through one
  /// alignment (M4.15 G2) and so which rows exist is one readable expression
  /// instead of a `Column` full of conditionals.
  ///
  /// Each row also carries **what kind of value it is**, which is what lets the
  /// panel set the counters in tabular figures and the box in the accent
  /// without the widget re-deciding from the label text — see [_ValueKind].
  List<_ScheduleRowData> _scheduleRows(
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

    return <_ScheduleRowData>[
      _ScheduleRowData(
        label: l10n.cardDetailDueLabel,
        value: date(state.dueAt, whenNull: unscheduled),
      ),
      _ScheduleRowData(
        label: l10n.cardDetailLearnedLabel,
        value: date(state.learnedAt, whenNull: unscheduled),
      ),
      _ScheduleRowData(
        label: l10n.cardDetailLastAnsweredLabel,
        value: date(
          state.lastAnsweredAt,
          whenNull: l10n.cardDetailNeverAnsweredValue,
        ),
      ),
      _ScheduleRowData(
        label: l10n.cardDetailReviewsLabel,
        value: '${state.answerCount}',
        kind: _ValueKind.count,
      ),
      _ScheduleRowData(
        label: l10n.cardDetailLapsesLabel,
        value: '${state.lapseCount}',
        kind: _ValueKind.count,
      ),
      if (state.schedulerType == SchedulerType.eightBox &&
          state.currentBox != null)
        _ScheduleRowData(
          label: l10n.cardDetailBoxLabel,
          value: '${state.currentBox}',
          kind: _ValueKind.progress,
        ),
      if (state.schedulerType == SchedulerType.sm2) ...<_ScheduleRowData>[
        if (state.easeFactor != null)
          _ScheduleRowData(
            label: l10n.cardDetailEaseLabel,
            value: state.easeFactor!.toStringAsFixed(2),
            kind: _ValueKind.count,
          ),
        if (state.intervalDays != null)
          _ScheduleRowData(
            label: l10n.cardDetailIntervalLabel,
            value: l10n.cardDetailDayCount(state.intervalDays!),
            kind: _ValueKind.count,
          ),
        if (state.repetitions != null)
          _ScheduleRowData(
            label: l10n.cardDetailRepetitionsLabel,
            value: '${state.repetitions}',
            // The card's position in the SM-2 chain, which is what `Box` is in
            // the eight-box one — the same meaning, so the same emphasis.
            kind: _ValueKind.progress,
          ),
      ],
    ];
  }
}

/// What a schedule value *is*, which decides how it is set.
enum _ValueKind {
  /// A date or a placeholder — prose, set like prose.
  text,

  /// A counter. Tabular figures, so a column of them lines up digit for digit
  /// instead of shifting with whichever glyphs it happens to contain.
  count,

  /// The one number the reader is tracking. Tabular like a counter and in the
  /// brand accent, because a panel where every row is equally quiet gives the
  /// box no way to be found.
  progress,
}

/// One row of the schedule panel: what it says and what kind of value it holds.
@immutable
class _ScheduleRowData {
  const _ScheduleRowData({
    required this.label,
    required this.value,
    this.kind = _ValueKind.text,
  });

  final String label;
  final String value;
  final _ValueKind kind;
}

/// The band's heading (M4.15 W2).
///
/// `sectionLabel` in tracked capitals, which is what every other group heading
/// in the app wears — it used to be `titleSmall`, indistinguishable from the
/// content under it except for its weight.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        label.toUpperCase(),
        style: context.textStyles.sectionLabel.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// The display state as a chip, drawn with the same coloured dot the list row
/// uses so colour is never the only signal (D5).
class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});

  final CardState state;

  @override
  Widget build(BuildContext context) {
    return _Chip(
      background: context.semanticColors.surfaceMuted,
      leading: Container(
        width: _stateDotSize,
        height: _stateDotSize,
        decoration: BoxDecoration(
          color: context.cardStateColor(state),
          shape: BoxShape.circle,
        ),
      ),
      label: context.cardStateLabel(state),
      labelColor: context.colors.onSurface,
    );
  }
}

/// The user's flag, present only when set — the detail screen shows it and
/// never toggles it (BR-92, BR-239).
///
/// **The same warm container the due chip wears**, because it is the same kind
/// of statement: a mark the user put on this card that they expect to find
/// again. It replaces a black `onSurface` glyph on the page ground, which is
/// what made the flag read as chrome rather than as a mark.
///
/// **The glyph is `onDueContainer`, and `warning` was measured and rejected.**
/// The warm family is the right one and `warning` is its loudest member, but on
/// `dueContainer` it comes out at **4.04:1** in light — below the 4.5 an
/// `AppIconSize.sm` glyph needs, and `card_detail_screen_visual_audit_test.dart`
/// fails on exactly that number. `onDueContainer` is the ink that pair was
/// measured *as*, so the chip stays warm and stays legible; the flag reads by
/// shape either way, which is the same argument the previous `onSurface` glyph
/// made.
class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return _Chip(
      background: semantic.dueContainer,
      leading: Icon(
        Icons.flag,
        size: AppIconSize.sm,
        color: semantic.onDueContainer,
      ),
      label: label,
      labelColor: semantic.onDueContainer,
    );
  }
}

/// The one chip shape this band draws: a pill with a mark and a word.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.background,
    required this.leading,
    required this.label,
    required this.labelColor,
  });

  final Color background;
  final Widget leading;
  final String label;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          leading,
          const SizedBox(width: AppSpacing.sm),
          // `Flexible`, because a `Wrap` hands its children the band's full
          // width and a `Row` past it simply overflows — a long state name at
          // 320dp with a 2.0 scaler is the case that finds it.
          Flexible(
            child: Text(
              label,
              style: context.texts.bodyMedium?.copyWith(color: labelColor),
            ),
          ),
        ],
      ),
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
          label.toUpperCase(),
          style: context.textStyles.sectionLabel.copyWith(
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

/// The schedule, as an inset panel.
///
/// **A ground of its own, and no rule between the rows.** Six key/value pairs
/// lying on the page ground read as loose text that happens to be aligned; the
/// muted fill says they are one table, which is what makes the alignment worth
/// having. Dividers were the other way to say it and would have said it six
/// times.
class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel({required this.rows});

  final List<_ScheduleRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.semanticColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The gap goes *between* rows, not under every one: a trailing `sm`
          // inside a padded panel makes the bottom inset 24 where the top is
          // 16, and nothing chose that.
          for (var index = 0; index < rows.length; index++) ...<Widget>[
            if (index > 0) const SizedBox(height: AppSpacing.sm),
            _ScheduleRow(row: rows[index]),
          ],
        ],
      ),
    );
  }
}

/// One label/value pair of the schedule.
///
/// **Two columns, and the label column is fixed**, so every value starts at the
/// same x (M4.15 G2) instead of being pushed around by the length of the word
/// beside it. The column scales with the text, because a constant dp would clip
/// the longest label in either language at 2.0 — and Vietnamese runs longer
/// than English here.
///
/// **Past a point the two columns stop fitting, and then it stacks.** At 320dp
/// with a 2.0 scaler the label column alone is more than half the panel, which
/// leaves less than one word for the value. Nothing overflows and nothing
/// throws, so the failure is silent: the value simply lays out past its column.
/// Below the threshold the row becomes the same label-over-value shape the
/// content band already uses, which keeps the value readable at the cost of
/// G2's alignment — an alignment nobody can read when the text it aligns is cut
/// off.
class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.row});

  final _ScheduleRowData row;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = MediaQuery.textScalerOf(
          context,
        ).scale(_labelColumnWidth);
        final fitsBeside =
            labelWidth + AppSpacing.md <=
            constraints.maxWidth * _maxLabelColumnFraction;

        return fitsBeside
            ? _SideBySide(row: row, labelWidth: labelWidth)
            : _Stacked(row: row);
      },
    );
  }
}

/// The two-column form, which is what G2 measures.
class _SideBySide extends StatelessWidget {
  const _SideBySide({required this.row, required this.labelWidth});

  final _ScheduleRowData row;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: labelWidth,
          child: Text(row.label, style: _labelStyle(context)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(row.value, style: _valueStyle(context, row.kind))),
      ],
    );
  }
}

/// The narrow form: label over value, both on the panel's left edge.
class _Stacked extends StatelessWidget {
  const _Stacked({required this.row});

  final _ScheduleRowData row;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(row.label, style: _labelStyle(context)),
        Text(row.value, style: _valueStyle(context, row.kind)),
      ],
    );
  }
}

/// The left column: `bodyMedium` on the muted ink, one rung up from the
/// `bodySmall` it used to be. The panel is the screen's data table and a label
/// nobody can read at arm's length is not a label.
TextStyle? _labelStyle(BuildContext context) =>
    context.texts.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant);

/// The right column: same rung as the label, heavier, and darker — the value is
/// the answer and the label is the question.
///
/// **`withWeight`, not `copyWith(fontWeight:)`.** The body face is a variable
/// font, so `copyWith` alone moves the declared weight without moving the
/// `wght` axis: it renders at the old weight and reports the new one.
TextStyle? _valueStyle(BuildContext context, _ValueKind kind) {
  final base = context.texts.bodyMedium;
  if (base == null) return null;

  return AppTypography.withWeight(base, FontWeight.w600).copyWith(
    color: switch (kind) {
      _ValueKind.text || _ValueKind.count => context.colors.onSurface,
      _ValueKind.progress => context.semanticColors.primaryAccent,
    },
    fontFeatures: switch (kind) {
      _ValueKind.text => null,
      _ValueKind.count ||
      _ValueKind.progress => const <FontFeature>[FontFeature.tabularFigures()],
    },
  );
}

/// The state dot's diameter, matching the list row's — colour and position
/// carry it, not size.
const double _stateDotSize = 10;

/// The unscaled width of the schedule's label column, sized to the longest
/// label in either language at 1.0×.
///
/// **136, up from 116 with the labels.** The column was measured against
/// `bodySmall`; the labels are `bodyMedium` now, which is the same 14/12 ratio
/// the number moved by. `Trả lời gần nhất` is what sets it.
const double _labelColumnWidth = 136;

/// How much of the row the scaled label column may take before the pair stacks.
///
/// Not a design value and deliberately not a token: it is this grid's own
/// layout rule. Past half the row the remainder stops being able to hold one
/// word at the scale that got it there, and a value laid out past its column is
/// worse than a taller row.
///
/// **Half, where it used to be 0.45.** The panel's own `lg` padding took 32dp
/// out of the width the fraction is measured against, so the previous number
/// stacked a grid that still fitted comfortably at 390dp.
const double _maxLabelColumnFraction = 0.5;
