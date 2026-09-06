import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';

/// A label and the control it names, side by side while both fit and stacked
/// when they do not.
///
/// **Two rows on the import wizard were the only ones that did not measure**
/// (SC-C7-02): the column-mapping row and the sheet selector both split their
/// line 50/50 between an `Expanded` label and an `Expanded` `MxDropdown`, with
/// no fallback. At `textScaler` 2.0 that gives the dropdown half a phone: at
/// 360×800 its box came out 144dp while the selected `Pronunciation` wanted
/// 216.95 and `RenderParagraph.didExceedMaxLines` was true — so the half the
/// step exists to decide was the half that got cut.
///
/// Three components on the same screen already do this and each says why:
/// `card_import_source_step_widget.dart` stacks its option pair,
/// `card_import_row_preview_widget.dart` stacks Front over Back below
/// `_twoColumnMinWidth`, and `card_import_stepper_widget.dart` measures with a
/// `TextPainter` before choosing a face. This is that same shape, named once
/// so the two rows cannot drift apart again.
///
/// **The threshold is scaled by the live text factor**, which is what makes it
/// a measurement rather than a breakpoint: the line does not get narrower at
/// text scale 2.0, the words get wider, and it is the ratio between them that
/// decides whether two columns still work.
class CardImportPairWidget extends StatelessWidget {
  const CardImportPairWidget({
    required this.label,
    required this.control,
    super.key,
  });

  /// What the control is for. Sits left in a row, above it in a stack.
  final Widget label;

  /// The control itself — a full-width one when stacked, which is the point.
  final Widget control;

  /// Below this many logical pixels at `textScaler` 1.0, the pair stacks.
  ///
  /// Read off the two arrangements rather than picked: at scale 1.0 the
  /// wizard's panel gives this row 329dp and the selected label paints at
  /// 109.5, so half a line is ample and the row stays. At 2.0 the same label
  /// wants 216.95, which needs 442 of line for two columns — more than any
  /// supported phone has. 240 sits between the two with room on both sides, so
  /// no ordinary render moves and every doubled one stacks.
  static const double inlinePairMinWidth = 240;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final threshold = MediaQuery.textScalerOf(
          context,
        ).scale(inlinePairMinWidth);

        if (constraints.maxWidth < threshold) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // `xs`, the app's label-to-control seam — the same one
              // `study_options_section_widget.dart` puts between a group's
              // name and the group.
              label,
              const SizedBox(height: AppSpacing.xs),
              control,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: label),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: control),
          ],
        );
      },
    );
  }
}
