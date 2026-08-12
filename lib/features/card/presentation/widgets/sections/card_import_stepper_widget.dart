import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../states/card_import_state.dart';

/// The three-step indicator (wireframe M4.12 W1).
///
/// Display only, deliberately: steps advance through the sticky actions, so a
/// node is never tappable and there is no way to arrive on a step whose
/// input does not exist yet (I2). The structure never changes with loading or
/// error — only the emphasis moves.
class CardImportStepperWidget extends StatelessWidget {
  const CardImportStepperWidget({required this.current, super.key});

  final CardImportStep current;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      context.l10n.cardImportStepSourceLabel,
      context.l10n.cardImportStepPreviewLabel,
      context.l10n.cardImportStepImportLabel,
    ];

    return Row(
      children: <Widget>[
        for (var step = 0; step < labels.length; step++) ...<Widget>[
          if (step > 0)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
          ),
        ],
      ],
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.label,
    required this.isCurrent,
    required this.isReached,
  });

  final int index;
  final String label;
  final bool isCurrent;
  final bool isReached;

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
      label: context.l10n.cardImportStepSemantics(index + 1),
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
      ),
    );
  }
}
