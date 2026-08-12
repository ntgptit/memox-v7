import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../states/card_import_state.dart';

/// The three-step indicator (wireframe M4.12 W1).
///
/// Display only, deliberately: steps advance through the sticky actions, so a
/// node is never tappable and there is no way to arrive on a step whose input
/// does not exist yet (I2). The structure never changes with loading or error
/// — only the emphasis moves.
///
/// **Two presentations, measured rather than guessed.** The full row — three
/// labelled nodes with connectors — fits a phone at ordinary type, but 320dp
/// at double text scale (or Vietnamese labels) cannot hold three labels
/// beside three circles. The build measures the labels with a [TextPainter]
/// under the live text scale; when they cannot fit, the labels leave the row
/// and only the current step's label renders on its own line — full-size,
/// never shrunk through a FittedBox into an unreadable thumbnail. Semantics
/// carry "Step n of 3" plus each step's name in both presentations, so what
/// a screen reader hears never depends on what happened to fit.
class CardImportStepperWidget extends StatelessWidget {
  const CardImportStepperWidget({required this.current, super.key});

  final CardImportStep current;

  /// The row's non-label spend per step: the numbered circle and its label
  /// gap, plus a connector's minimum readable length. Used only to decide
  /// which presentation fits.
  static const double _fixedWidthPerStep =
      AppSpacing.xl + AppSpacing.xs + 2 * AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      context.l10n.cardImportStepSourceLabel,
      context.l10n.cardImportStepPreviewLabel,
      context.l10n.cardImportStepImportLabel,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            _labelsWidth(context, labels) + labels.length * _fixedWidthPerStep >
            constraints.maxWidth;

        final row = Row(
          children: <Widget>[
            for (var step = 0; step < labels.length; step++) ...<Widget>[
              if (step > 0)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Divider(
                      color: step <= current.index
                          ? context.colors.primary
                          : context.colors.outlineVariant,
                    ),
                  ),
                ),
              _StepNode(
                index: step,
                label: labels[step],
                isCurrent: step == current.index,
                isReached: step <= current.index,
                shouldShowLabel: !isCompact,
              ),
            ],
          ],
        );

        if (!isCompact) return row;

        // The compact face: the three nodes keep the row, and the current
        // step's name gets a whole line to itself instead of an ellipsis.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            row,
            const SizedBox(height: AppSpacing.xs),
            ExcludeSemantics(
              // The node's own semantics already announce it.
              child: Text(
                labels[current.index],
                style: context.texts.labelLarge?.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// The three labels' widths under the live text scale — what actually
  /// decides the presentation, so Vietnamese and 2.0× type make the same
  /// honest choice English at 1.0× does.
  double _labelsWidth(BuildContext context, List<String> labels) {
    final scaler = MediaQuery.textScalerOf(context);
    var width = 0.0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: context.texts.labelLarge),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      width += painter.width;
      painter.dispose();
    }

    return width;
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.label,
    required this.isCurrent,
    required this.isReached,
    required this.shouldShowLabel,
  });

  final int index;
  final String label;
  final bool isCurrent;
  final bool isReached;
  final bool shouldShowLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Reached steps carry the primary pair; unreached stay on the quiet
    // container. Emphasis is doubled by weight, so colour is never the only
    // signal (W7).
    final background = isReached ? colors.primary : colors.surfaceContainerHigh;
    final foreground = isReached ? colors.onPrimary : colors.onSurfaceVariant;

    return Semantics(
      selected: isCurrent,
      // The name rides the semantics in both presentations, so hiding the
      // visual label never hides the step from a screen reader (W7).
      label: context.l10n.cardImportStepNamedSemantics(
        context.l10n.cardImportStepSemantics(index + 1),
        label,
      ),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // A plain decorated circle, not CircleAvatar: the avatar paints a
          // PhysicalShape and a DefaultTextStyle from ThemeData's legacy
          // primary swatch, neither of which resolves to a palette token.
          Container(
            width: AppSpacing.xl,
            height: AppSpacing.xl,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: context.texts.labelMedium?.copyWith(color: foreground),
            ),
          ),
          if (shouldShowLabel) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: isCurrent
                  ? context.texts.labelLarge?.copyWith(color: colors.onSurface)
                  : context.texts.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
