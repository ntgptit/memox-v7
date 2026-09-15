import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';

/// A labeled switch row.
///
/// **Exists so no feature builds a `Switch` or `SwitchListTile` again.** The
/// repo has exactly two recorded spellings of "a switch beside its words",
/// and this widget owns both, because the difference is a semantics decision
/// and not a layout preference:
///
/// One shape since A20.1 P2-13: a `SwitchListTile` — the whole row is the
/// target, and the tile merges label and control into one spoken node with
/// one state. The "announced" variant that put the value in words beside the
/// switch's own toggle stacked two channels for one fact (A19-19) and is gone.
class MxSwitchRow extends StatelessWidget {
  const MxSwitchRow({
    required this.label,
    required this.isOn,
    required this.onChanged,
    super.key,
  });

  /// Already-localized words beside the switch.
  final String label;

  final bool isOn;

  /// `null` locks the control.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    // **One state channel** (A20.1 P2-13, A19-19). The row used to offer a
    // second variant that put `Semantics(label, value: 'On')` on the switch
    // beside the switch's own `toggled` flag, so a reader heard the state
    // twice — "Reminders, On, switch, on". `SwitchListTile` is Material's
    // grammar: the label is the tile's name and the toggle is the switch's
    // own flag beneath it — Flutter 3.44 keeps that node under the tile —
    // and nothing writes the state as text a second time.
    //
    // **Its own transparent `Material`, so the row can sit on any surface.**
    // A `SwitchListTile` paints its ink on the nearest `Material` ancestor;
    // inside a non-tappable `MxCard` — a bare `DecoratedBox`, by design —
    // the nearest one is the Scaffold's, behind the card's opaque fill, and
    // the framework rightly flags the splash as invisible. Transparency
    // adds a paint layer for the ink and no colour of its own.
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile(
        value: isOn,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        // `body-lg`, the row title rung every `ListTile` uses (#431 P2-12).
        title: Text(label, style: context.texts.bodyLarge),
      ),
    );
  }
}
