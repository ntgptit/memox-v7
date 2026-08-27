import 'package:flutter/material.dart';

/// A checkbox row in a pick-many list.
///
/// **Exists so no feature builds a `CheckboxListTile` again.** One site did
/// (the tag filter sheet), and its three choices are the ones this widget
/// fixes as the house spelling: the box leads (`leading` affinity — in a
/// pick-many list the mark is what the eye scans down, so it sits on the
/// reading edge), the row supplies no gutter of its own (`contentPadding`
/// zero — the sheet or card around it owns the inset), and the whole row is
/// the target with the tile merging label and box into one spoken node.
///
/// The checkbox's colours come entirely from `CheckboxThemeData`.
class MxCheckboxRow extends StatelessWidget {
  const MxCheckboxRow({
    required this.label,
    required this.isChecked,
    required this.onToggle,
    this.subtitle,
    super.key,
  });

  /// Already-localized words for the choice.
  final String label;

  /// Secondary line under the label — a count, a hint.
  final String? subtitle;

  final bool isChecked;

  /// Called on any tap; the new value is `!isChecked`, so the caller toggles
  /// rather than receives. `null` locks the row.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: isChecked,
      onChanged: onToggle == null ? null : (_) => onToggle!(),
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle!),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}
