import 'package:flutter/material.dart';

import '../../core/theme/theme_context_extension.dart';

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
/// Whether the group is a *list* — rows that need telling apart from each
/// other — or a *block* of choices inside a larger group.
///
/// **An enum, because the answer is a meaning and the two callers differ on
/// it** (M100.0). Appearance and Language are the whole content of their card:
/// nothing else is in there, so the rows are the list and a divider between
/// them is what says so. Study defaults' rows sit between a text field, a note
/// and a Save button — a line across them there cuts a group in half rather
/// than dividing a list, which is what the owner's review settled after seeing
/// both rendered.
enum MxRadioRowsShape {
  /// Rows with nothing between them. Right when the group is one part of a
  /// card that holds other things too.
  block,

  /// Rows divided by `borderDivider`, edge to edge. Right when the rows *are*
  /// the card's content.
  list,
}

class MxRadioRows<T> extends StatelessWidget {
  const MxRadioRows({
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    this.subtitleOf,
    this.isEnabled = true,
    this.contentPadding = EdgeInsets.zero,
    this.shape = MxRadioRowsShape.block,
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

  /// See [MxRadioRowsShape]. Defaults to [MxRadioRowsShape.block] — a divider
  /// is something a caller asks for, because only the caller knows whether its
  /// rows are the card or a part of it.
  final MxRadioRowsShape shape;

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
            for (final (index, value) in values.indexed) ...<Widget>[
              // Between rows only — never above the first or below the last,
              // where it would read as the card's own edge coming back.
              if (index > 0 && shape == MxRadioRowsShape.list)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: context.semanticColors.borderDivider,
                ),
              RadioListTile<T>(
                value: value,
                enabled: isEnabled,
                title: Text(labelOf(value)),
                subtitle: subtitleOf == null ? null : Text(subtitleOf!(value)),
                contentPadding: contentPadding,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
