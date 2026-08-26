import 'package:flutter/material.dart';

import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/theme_context_extension.dart';

/// What a schedule value *is*, which is what decides how it is drawn.
///
/// Presentation-only and deliberately not a domain concept: the domain knows an
/// `int currentBox`, and "the one number on this panel that says how far the
/// card has got" is a statement about the panel.
enum CardMetricKind {
  /// A formatted date. Proportional figures — a date is read, not compared
  /// column-wise with the date above it.
  date,

  /// A count or a measure. Tabular figures, so `7` and `12` put their units in
  /// the same place down the column.
  numeric,

  /// The scheduler's own position — `eight_box`'s box. Tabular *and* accented:
  /// it is the one value on the panel that answers "how far along is this
  /// card", which is the question the panel is usually opened for.
  ///
  /// **SM-2 has no equivalent and does not get one.** Ease, interval and
  /// repetitions are three numbers that only mean something together; picking
  /// one to accent would be inventing a progress metric SM-2 does not define
  /// (BR-243).
  schedulerProgress,
}

/// One label/value pair of the schedule, with its glyph and its kind attached.
@immutable
final class CardMetric {
  const CardMetric._(this.label, this.value, this.icon, this.kind);

  const CardMetric.date(String label, String value, IconData icon)
    : this._(label, value, icon, CardMetricKind.date);

  const CardMetric.numeric(String label, String value, IconData icon)
    : this._(label, value, icon, CardMetricKind.numeric);

  final String label;
  final String value;

  /// Beside the words, never instead of them. A well with a glyph is what makes
  /// the grid scannable; the label is what makes it readable.
  final IconData icon;

  final CardMetricKind kind;
}

/// One cell of the progress panel's grid: a glyph in a well, then the label over
/// its value.
///
/// **The well is decoration and the text is the content**, which is why the
/// glyph takes `primaryAccent` on `surfaceMuted` (6.36:1 light, 4.66:1 dark) and
/// the label and value take the ordinary ink pair. Nothing here is a control, so
/// nothing here carries a touch target — a read-only cell may be as compact as
/// its type allows.
class CardMetricWidget extends StatelessWidget {
  const CardMetricWidget({required this.metric, super.key});

  final CardMetric metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: _wellSize,
          height: _wellSize,
          decoration: BoxDecoration(
            color: context.semanticColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            metric.icon,
            size: AppIconSize.sm,
            color: context.semanticColors.primaryAccent,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(metric.label, style: cardMetricLabelStyle(context)),
              Text(
                metric.value,
                style: cardMetricValueStyle(context, metric.kind),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The label half — quiet, and a rung below the value it introduces.
TextStyle cardMetricLabelStyle(BuildContext context) =>
    context.texts.bodySmall!.copyWith(color: context.colors.onSurfaceVariant);

/// The value half, by kind.
///
/// `AppTypography.withWeight`, never a bare `fontWeight:` — both faces are
/// variable fonts and carry a `wght` axis, which the renderer consults instead
/// of `TextStyle.fontWeight`, so a copyWith alone reports w600 to every test and
/// paints w400 on the device.
TextStyle cardMetricValueStyle(BuildContext context, CardMetricKind kind) {
  final base = AppTypography.withWeight(
    context.texts.bodyMedium!,
    FontWeight.w600,
  );

  return switch (kind) {
    CardMetricKind.date => base.copyWith(color: context.colors.onSurface),
    CardMetricKind.numeric => base.copyWith(
      color: context.colors.onSurface,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    ),
    CardMetricKind.schedulerProgress => base.copyWith(
      // 6.36:1 light and 4.66:1 dark on `surfaceMuted`, 7.27 / 5.51 on
      // `surface` — the accent as text, not `ColorScheme.primary`, which is a
      // fill colour and fails AA as a bare label on the dark panel.
      color: context.semanticColors.primaryAccent,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    ),
  };
}

/// The glyph well. Square, so a column of cells has one left edge whatever the
/// glyph inside it is.
const double _wellSize = 32;
