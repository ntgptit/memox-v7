import 'package:flutter/material.dart';

import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_radius.dart';
import '../../../../../core/theme/foundations/app_sizing.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/typography/app_typography.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';

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
/// glyph takes `primary` on `surfaceMuted` (6.36:1 light, 8.30:1 dark) and
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
          width: AppSizing.controlDense,
          height: AppSizing.controlDense,
          decoration: BoxDecoration(
            color: context.semanticColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: MxIcon(metric.icon, ink: AppInk.accent, size: MxIconSize.sm),
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
    context.texts.bodySmall!.inked(context, AppInk.quiet);

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
    CardMetricKind.date => base.inked(context, AppInk.stated),
    CardMetricKind.numeric => base.inked(
      context,
      AppInk.stated,
      isTabular: true,
    ),
    CardMetricKind.schedulerProgress =>
      base
          .copyWith(
            // 6.36:1 light and 4.66:1 dark on `surfaceMuted`, 7.27 / 5.51 on
            // `surface` — the accent as text (`AppInk.accent` is `primary`, which
            // since M100.18 reads as text on the dark panel too).
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          )
          .inked(context, AppInk.accent),
  };
}
