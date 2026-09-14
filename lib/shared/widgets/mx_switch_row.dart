import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import 'mx_focus_ring.dart';
import 'mx_switch.dart';

/// A labeled switch row.
///
/// **Exists so no feature builds a `Switch` or `SwitchListTile` again.** The
/// repo has exactly two recorded spellings of "a switch beside its words",
/// and this widget owns both, because the difference is a semantics decision
/// and not a layout preference:
///
/// One shape since A20.1 P2-13 — the whole row is the target, and label and
/// control are one spoken node with one state. The "announced" variant that
/// put the value in words beside the switch's own toggle stacked two channels
/// for one fact (A19-19) and is gone. **Drawn to the handoff Switch since
/// M100.92:** the track and thumb are [MxSwitch], because Material's `Switch`
/// fixes its track at 52 × 32 and no theme slot reaches 44 × 26.
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
    final isEnabled = onChanged != null;
    // **One state channel** (A20.1 P2-13, A19-19). The row used to offer a
    // second variant that put `Semantics(label, value: 'On')` beside the
    // switch's own `toggled` flag, so a reader heard the state twice —
    // "Reminders, On, switch, on". Here the merged node takes the label as its
    // name and `toggled` as its state, and the painted switch is excluded from
    // semantics, so nothing states it a second time.
    //
    // **Its own transparent `Material`, so the row can sit on any surface.**
    // The ink paints on the nearest `Material` ancestor; inside a non-tappable
    // `MxCard` — a bare `DecoratedBox`, by design — that is the Scaffold's,
    // behind the card's opaque fill, and the framework rightly flags the
    // splash as invisible. Transparency adds a paint layer for the ink and no
    // colour of its own.
    return MergeSemantics(
      child: Semantics(
        toggled: isOn,
        enabled: isEnabled,
        child: MxFocusRing(
          // Square, like `MxListTile`: the ring traces the row the ink fills.
          borderRadius: BorderRadius.zero,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: isEnabled ? () => onChanged!(!isOn) : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSizing.touchTarget,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        label,
                        // `body-lg`, the row title rung every `ListTile` uses
                        // (#431 P2-12).
                        style: context.texts.bodyLarge!.inked(
                          context,
                          isEnabled ? AppInk.stated : AppInk.disabled,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ExcludeSemantics(
                      child: MxSwitch(isOn: isOn, onChanged: onChanged),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
