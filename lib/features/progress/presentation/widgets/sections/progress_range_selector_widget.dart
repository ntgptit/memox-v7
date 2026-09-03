import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_pill_button.dart';
import '../../../domain/models/progress_range_model.dart';
import '../support/progress_labels_widget.dart';

/// The 7 / 30 day switch (BR-184).
///
/// **Selection is never colour alone.** `chipTheme` turns Material's checkmark
/// off, because the card list's filter pills carry counts and a tick beside a
/// number reads as part of it — so the selected pill here carries its own
/// leading tick. Fill, border and glyph then all say the same thing, which is
/// what a person who cannot separate the two fills needs, and what a greyscale
/// screenshot has to survive.
///
/// **Both pills stay enabled at all times.** Switching costs no read — both
/// windows ride on one snapshot — so there is no loading state in which a
/// disabled pill would be honest.
///
/// Wrapped in a `Semantics` group so a screen reader says what the choice is
/// about before it reads the two options; each pill keeps Material's own
/// selected flag, which is what actually announces which one is active.
class ProgressRangeSelectorWidget extends StatelessWidget {
  const ProgressRangeSelectorWidget({
    required this.range,
    required this.onRangeChanged,
    super.key,
  });

  final ProgressRange range;
  final ValueChanged<ProgressRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: context.l10n.progressRangeSelectorSemanticLabel,
      child: Row(
        spacing: AppSpacing.sm,
        children: <Widget>[
          for (final ProgressRange option in ProgressRange.values)
            MxPillButton(
              label: context.progressRangeLabel(option),
              semanticLabel: context.progressRangeSemanticLabel(option),
              isSelected: option == range,
              // The tick is the component's now (M100.36 4M): every selected
              // pill in the app carries it in a slot that is laid out either
              // way, so this screen stopped being the one that drew its own.
              onPressed: () => onRangeChanged(option),
            ),
        ],
      ),
    );
  }
}
