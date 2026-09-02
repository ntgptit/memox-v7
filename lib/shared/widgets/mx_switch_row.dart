import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/extensions/theme_context_extension.dart';

/// A labeled switch row.
///
/// **Exists so no feature builds a `Switch` or `SwitchListTile` again.** The
/// repo has exactly two recorded spellings of "a switch beside its words",
/// and this widget owns both, because the difference is a semantics decision
/// and not a layout preference:
///
/// - the default is a `SwitchListTile`: the whole row is the target, and the
///   tile merges label and control into one spoken node. Dense form rows
///   (the import step's header and duplicate toggles) read this way.
/// - with [announcedValue] set, the row is the reminder pattern (M6 R7,
///   owner-reviewed): the label is visible but excluded, the switch alone
///   carries `Semantics(label, value)` so a reader hears the *value in words*
///   — and the label is deliberately the tap target for nothing, because a
///   row that flips a setting when the user meant to read it is the wrong
///   trade for something that then asks the OS for a permission.
class MxSwitchRow extends StatelessWidget {
  const MxSwitchRow({
    required this.label,
    required this.isOn,
    required this.onChanged,
    this.announcedValue,
    super.key,
  });

  /// Already-localized words beside the switch.
  final String label;

  final bool isOn;

  /// `null` locks the control.
  final ValueChanged<bool>? onChanged;

  /// The value spoken in words ("On" / "Off", localized). Setting it switches
  /// the row to the announced pattern described above.
  final String? announcedValue;

  @override
  Widget build(BuildContext context) {
    if (announcedValue == null) {
      // **Its own transparent `Material`, so the row can sit on any surface.**
      // A `SwitchListTile` paints its ink on the nearest `Material` ancestor;
      // inside a non-tappable `MxCard` — a bare `DecoratedBox`, by design —
      // the nearest one is the Scaffold's, behind the card's opaque fill, and
      // the framework rightly flags the splash as invisible. Transparency
      // adds a paint layer for the ink and no colour of its own, so callers
      // that sit on the bare page render exactly as before.
      return Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          value: isOn,
          onChanged: onChanged,
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: context.texts.bodyMedium),
        ),
      );
    }

    return Row(
      children: <Widget>[
        // Excluded, and the label moves onto the switch: the visible text and
        // the control are two nodes, so a reader focusing the control would
        // otherwise hear "Off, switch" with no idea what is off (WCAG 4.1.2)
        // — and without the exclusion the same words are announced twice.
        Expanded(
          child: ExcludeSemantics(
            child: Text(label, style: context.texts.bodyLarge),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Semantics(
          label: label,
          value: announcedValue,
          child: Switch(value: isOn, onChanged: onChanged),
        ),
      ],
    );
  }
}
