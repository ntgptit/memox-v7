import 'package:flutter/material.dart';

/// The handoff Slider (D): a scrubber for a bounded value — a daily goal, a
/// speech rate. The theme owns every colour; this widget names the control.
/// No production caller yet (owner decision 10).
///
/// **The name is merged onto the slider's own node.** `Slider` is a semantics
/// node of its own, so a bare `Semantics(label:)` above it names a node the
/// reader does not focus and leaves the slider unnamed. `MergeSemantics` folds
/// the label, the value and the adjust actions into one node.
class MxSlider extends StatelessWidget {
  const MxSlider({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.min = 0,
    this.max = 1,
    this.divisions,
    super.key,
  });

  final double value;

  /// `null` disables the slider.
  final ValueChanged<double>? onChanged;

  /// Already-localized name of what the slider sets.
  final String semanticLabel;

  final double min;
  final double max;

  /// Discrete steps between [min] and [max]; `null` is continuous.
  final int? divisions;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      label: semanticLabel,
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    ),
  );
}
