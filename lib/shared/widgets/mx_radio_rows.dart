import 'package:flutter/material.dart';

/// A pick-one group drawn as radio rows.
///
/// **Exists so no feature builds a `RadioListTile` again.** Two sites did
/// (the scheduler picker and the settings choice rows), and between them they
/// had already discovered everything this widget now owns:
///
/// - **its own transparent `Material`.** A `ListTile` paints its splash onto
///   the nearest `Material` ancestor, and inside a decorated card that
///   ancestor is *behind* the card's opaque fill — every ripple drawn and
///   then covered. The settings rows hand-wrote this fix; now it is
///   structural, the same move `MxPressable` made for `InkWell`.
/// - **the lock lives on each tile, with a guarded callback.**
///   `RadioGroup.onChanged` is required and non-nullable, so `isEnabled:
///   false` greys each row and takes it out of the focus order, while the
///   swallowing callback means a tap that somehow lands mid-write changes
///   nothing.
///
/// What stays with the caller: the choice type, its localized words, and any
/// announcement around the group (the settings lock announces itself with
/// its own `Semantics` — that is a screen's sentence, not the group's).
class MxRadioRows<T> extends StatelessWidget {
  const MxRadioRows({
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    this.subtitleOf,
    this.isEnabled = true,
    this.contentPadding = EdgeInsets.zero,
    super.key,
  });

  final List<T> values;

  /// `null` when nothing is picked yet.
  final T? selected;

  final ValueChanged<T> onChanged;

  /// Already-localized label for one choice.
  final String Function(T value) labelOf;

  /// Optional second line per choice.
  final String Function(T value)? subtitleOf;

  /// While false the whole group is locked.
  final bool isEnabled;

  /// The gutter each row supplies for itself. Zero inside a card that already
  /// pads its content; a horizontal inset when the row's ink should span a
  /// card that pads vertically only.
  final EdgeInsetsGeometry contentPadding;

  void _ignoreChange(T? _) {}

  void _onChanged(T? value) {
    if (value == null) {
      return;
    }
    onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      groupValue: selected,
      onChanged: isEnabled ? _onChanged : _ignoreChange,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final value in values)
              RadioListTile<T>(
                value: value,
                enabled: isEnabled,
                title: Text(labelOf(value)),
                subtitle: subtitleOf == null ? null : Text(subtitleOf!(value)),
                contentPadding: contentPadding,
              ),
          ],
        ),
      ),
    );
  }
}
