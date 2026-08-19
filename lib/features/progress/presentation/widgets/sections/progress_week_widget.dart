import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/progress_activity_day_model.dart';
import '../items/progress_week_bar_widget.dart';
import '../support/progress_labels_widget.dart';

/// The seven-day activity chart (W4).
///
/// **A `Table`, and the reason is geometry rather than tabular data.** W5 pins
/// three shared edges — every bar starts on one line (G8), ends on another
/// (G10), and every row is the same shape (G9). A `Row` per day cannot promise
/// that: each row would size its own label column, so "Wed" and "Today" would
/// start their bars at different x, and the difference grows with the text
/// scale. `IntrinsicColumnWidth` on the outer columns makes the framework
/// measure all seven labels together and give them one width, which is the
/// property the contract is written against.
///
/// **Horizontal bars, not vertical columns.** Measured, not preferred: at 320dp
/// with a text scale of 2.0 the card's content is 264dp wide, so seven columns
/// with six gaps leave under 31dp each — narrower than a three-digit figure and
/// than the weekday labels of either locale. Vertical columns survive there only
/// by clipping or by shrinking the type, and W6 forbids both. One row per day
/// also gives a screen reader one node per day, which a column chart cannot.
class ProgressWeekWidget extends StatelessWidget {
  const ProgressWeekWidget({required this.days, super.key});

  /// Exactly seven entries, oldest first, the last being today (BR-196).
  final List<ProgressActivityDay> days;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;
    final colors = context.colors;

    // The busiest day sets the scale, so the chart shows the shape of the week
    // rather than the shape of some fixed ceiling nobody reaches. Zero is a real
    // case — a fortnight off, with older history still on record — and it makes
    // every bar empty rather than dividing by nothing.
    final int busiest = days.fold<int>(
      0,
      (int max, ProgressActivityDay day) => math.max(max, day.totalCards),
    );

    // Flat, like every other card in a scrolling column (M99.26): two
    // competing depths in one column is what makes a list read as busy,
    // which is the reason the deck tile and the Study Home row already
    // gave. Progress was the only surface still taking the default.
    return MxCard(
      elevation: AppElevation.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.l10n.progressWeekSectionLabel,
            style: texts.labelLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Table(
            columnWidths: const <int, TableColumnWidth>{
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
              2: IntrinsicColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: <TableRow>[
              for (final (int index, ProgressActivityDay day) in days.indexed)
                _row(
                  context,
                  day: day,
                  busiest: busiest,
                  isToday: index == days.length - 1,
                  isLast: index == days.length - 1,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// One day.
  ///
  /// The row's whole sentence hangs off the **label** cell, and the other two
  /// cells are excluded: a `Table` gives no place to wrap a row, so the choice
  /// is one node per row anchored at the label, or three fragments per row in
  /// which the figure has lost the day it belongs to.
  TableRow _row(
    BuildContext context, {
    required ProgressActivityDay day,
    required int busiest,
    required bool isToday,
    required bool isLast,
  }) {
    final texts = context.texts;
    final colors = context.colors;
    final String label = context.progressDayLabel(day, isToday: isToday);
    // The gap belongs *between* rows, so the last one does not carry it — that
    // is what keeps the card's bottom padding equal to its top (G5) instead of
    // one gap taller.
    final EdgeInsets cellPadding = EdgeInsets.only(
      bottom: isLast ? 0 : AppSpacing.sm,
    );

    return TableRow(
      children: <Widget>[
        Padding(
          padding: cellPadding.copyWith(right: AppSpacing.sm),
          child: Semantics(
            label: context.l10n.progressWeekDaySemantics(label, day.totalCards),
            child: ExcludeSemantics(
              child: Text(
                label,
                style: texts.bodyMedium?.copyWith(
                  color: isToday ? colors.onSurface : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: cellPadding,
          child: ProgressWeekBarWidget(
            fraction: busiest == 0 ? 0 : day.totalCards / busiest,
          ),
        ),
        Padding(
          padding: cellPadding.copyWith(left: AppSpacing.sm),
          child: ExcludeSemantics(
            child: Text(
              '${day.totalCards}',
              textAlign: TextAlign.end,
              style: texts.bodyMedium?.copyWith(color: colors.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}
