import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../states/card_import_state.dart';

/// One stepper node's progress state — three visuals, not two. A completed
/// step swaps its number for a check; the current one keeps its number on
/// the primary pair; a future one keeps its number on the quiet container.
/// "Every index <= current" is deliberately *not* the rule: the Source step
/// is complete once a source exists, and Preview only once the mapping and
/// the importable count say so — completion is earned, not positional.
enum _NodeState { completed, current, future }

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
/// carry "Step n of 3", the step's name and its progress state in both
/// presentations, so what a screen reader hears never depends on what
/// happened to fit.
class CardImportStepperWidget extends StatelessWidget {
  const CardImportStepperWidget({
    required this.current,
    this.completed = const <CardImportStep>{},
    super.key,
  });

  final CardImportStep current;

  /// The steps that have *earned* their check (M4.12 stepper contract):
  /// Source once a source exists, Preview once the mapping is complete and
  /// something is importable. The screen computes this — the stepper only
  /// draws it.
  final Set<CardImportStep> completed;

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

    _NodeState stateOf(int step) {
      if (completed.contains(CardImportStep.values[step])) {
        return _NodeState.completed;
      }

      return step == current.index ? _NodeState.current : _NodeState.future;
    }

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
                      // The connector fills once the step *before* it is
                      // done — it reports progress earned, like the nodes.
                      color: stateOf(step - 1) == _NodeState.completed
                          ? context.colors.primary
                          : context.colors.outlineVariant,
                    ),
                  ),
                ),
              _StepNode(
                index: step,
                label: labels[step],
                state: stateOf(step),
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
                style: context.texts.labelLarge!.inked(context, AppInk.stated),
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
    required this.state,
    required this.shouldShowLabel,
  });

  final int index;
  final String label;
  final _NodeState state;
  final bool shouldShowLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Completed and current share the primary pair; the *glyph* tells them
    // apart — a check is a fact, a number is an address — so the distinction
    // survives any palette and colour is never the only signal (W7).
    final isReached = state != _NodeState.future;
    final background = isReached ? colors.primary : colors.surfaceContainerHigh;
    final foreground = isReached ? AppInk.onPrimary : AppInk.quiet;
    final stateLabel = switch (state) {
      _NodeState.completed => context.l10n.cardImportStepStateCompleted,
      _NodeState.current => context.l10n.cardImportStepStateCurrent,
      _NodeState.future => context.l10n.cardImportStepStateUpcoming,
    };

    return Semantics(
      selected: state == _NodeState.current,
      // Position, name and progress ride the semantics in both
      // presentations, so neither a hidden label nor a swapped glyph ever
      // hides the step from a screen reader (W7).
      label: context.l10n.cardImportStepStateSemantics(
        context.l10n.cardImportStepSemantics(index + 1),
        label,
        stateLabel,
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
            child: state == _NodeState.completed
                ? MxIcon(Icons.check, ink: foreground, size: MxIconSize.sm)
                : Text(
                    '${index + 1}',
                    style: context.texts.labelMedium!.inked(
                      context,
                      foreground,
                    ),
                  ),
          ),
          if (shouldShowLabel) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: state == _NodeState.current
                  ? context.texts.labelLarge!.inked(context, AppInk.stated)
                  : context.texts.labelMedium!.inked(context, AppInk.quiet),
            ),
          ],
        ],
      ),
    );
  }
}
