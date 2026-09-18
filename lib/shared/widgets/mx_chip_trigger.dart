import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_spacing.dart';
import 'mx_focus_ring.dart';
import 'mx_icon.dart';
import 'mx_tap_target.dart';

/// A compact chip that opens a menu instead of holding a selection —
/// "Newest first", "Manual · Due only".
///
/// **Why this is not `MxPillButton` with a flag.** `MxPillButton.isSelected`
/// is required, and a pill's whole accessibility contract (`hasSelectedState`,
/// `inMutuallyExclusiveGroup`) is built around it. `MxChipTrigger` must never
/// read as selected — not "selected: false" but no selection concept at all —
/// so it composes its own `InkWell` rather than a `ChoiceChip`.
///
/// **Ghost, not filled.** No fill, no border: [onPressed] fires a caller-owned
/// menu (a sheet, a `PopupMenuButton`, a `MenuAnchor`) — this widget renders
/// only the trigger and knows nothing about what opens.
class MxChipTrigger extends StatelessWidget {
  const MxChipTrigger({
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.semanticLabel,
    super.key,
  });

  /// Already-localized. The trigger never reaches for ARB itself.
  final String label;

  /// Null disables the trigger. Opens whatever caller-owned surface answers
  /// this menu — this widget never builds one itself.
  final VoidCallback? onPressed;

  /// Painted before the label, at the same size and gap as the trailing
  /// chevron. Null paints nothing — the slot is not reserved when absent, so
  /// the trigger does not carry a phantom 20dp width for a glyph nobody asked
  /// for.
  final IconData? leadingIcon;

  /// Replaces [label] for assistive technology when the visible text is not
  /// enough on its own (an abbreviation, a short code).
  final String? semanticLabel;

  /// The chip's own content height (handoff dimension table). Not promoted to
  /// `AppSizing` — that ladder holds a value only once more than one
  /// component renders it, and this is the first.
  static const double _contentHeight = 28;

  /// One ink for the label and both glyphs. Disabled is the design system's
  /// own `onDisabled` (38% of the primary ink) rather than a second alpha
  /// restated here.
  AppInk get _ink => onPressed == null ? AppInk.disabled : AppInk.quiet;

  @override
  Widget build(BuildContext context) {
    final AppInk ink = _ink;
    final BorderRadius shape = BorderRadius.circular(AppRadius.pill);

    // Semantics wraps the whole interactive shape because nothing here is a
    // built-in Material control (unlike `ChoiceChip`/`FilledButton`) that
    // would otherwise supply button semantics for free.
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        onTap: onPressed,
        // The 48 touch target on both axes, centred around the 28dp band and
        // redirecting hits in its padding to the band — the repo's one
        // technique for a target larger than the painted shape (the same one
        // `MxPillButton` uses). It sits *outside* the ring, so the ring and
        // the `InkWell` stay at the painted band.
        child: MxTapTarget(
          // `MxFocusRing` has to be the *ancestor* of the `InkWell` it rings:
          // a `Focus` node's `hasFocus` is true only for itself or an
          // ancestor of the focused node, never a descendant.
          child: MxFocusRing(
            borderRadius: shape,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onPressed,
                borderRadius: shape,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: SizedBox(
                    height: _contentHeight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppSpacing.xs,
                      children: <Widget>[
                        if (leadingIcon != null)
                          MxIcon(leadingIcon!, size: MxIconSize.sm, ink: ink),
                        Text(
                          label,
                          semanticsLabel: semanticLabel,
                          maxLines: 1,
                          softWrap: false,
                          style: context.texts.labelMedium!.inked(context, ink),
                        ),
                        MxIcon(
                          Icons.expand_more,
                          size: MxIconSize.sm,
                          ink: ink,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
