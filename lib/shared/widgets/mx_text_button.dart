import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// A low-emphasis action drawn as a bare label.
///
/// The third weight, under `MxActionButton`'s filled and outlined variants: an
/// action that belongs in the flow of the content rather than beside it —
/// *Show today's summary* is the first, and the one it was built for.
///
/// **It carries no horizontal padding, and that is the entire reason it exists
/// as a widget.** Material's `TextButton` insets its label by 12, so a bare link
/// placed at the screen gutter lands 12px further in than the heading and the
/// cards above it. Nothing on screen explains the step, and the eye reads it as
/// a misaligned element rather than as a button. Zero padding puts the label on
/// the same vertical line as everything else in the column.
///
/// **The 48 floor is kept as height, not as padding.** `AppSpacing` calls the
/// touch target a floor rather than a step for exactly this case: the label may
/// sit flush, but the thing a finger has to hit may not shrink to the height of
/// a line of text. So `minimumSize` carries the 48 while the visual inset stays
/// at zero — the same split `MxSearchField` makes between the pill it draws and
/// the box it is willing to be tapped in.
///
/// **The design reaches the same place from the other side.** Its `.mx-textlink`
/// keeps a small padding for the hover surface and cancels it with a negative
/// horizontal margin, so the label lands flush while the highlight still extends
/// past it. The visible result is the same and the mechanism is not worth
/// reproducing: a negative margin is a `Transform` in Flutter, and the highlight
/// here already extends well past the label vertically because the box is 48
/// tall. Where the two genuinely differ is height — the design's link is about
/// 24 — and the 48 floor wins, as it did for `MxSearchField` at M4.10z.
///
/// Takes no `Color`, no `TextStyle` and no padding override, for the reason
/// `MxActionButton` takes none: a component the caller can restyle is a
/// component that stops being a component the first time someone is in a hurry.
class MxTextButton extends StatelessWidget {
  const MxTextButton({required this.label, required this.onPressed, super.key});

  /// Already-localized. The screen owns the copy; the button never reads ARB.
  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        // The width floor is zero rather than Material's 64: a link that pads
        // itself out to a minimum width re-introduces the misalignment on the
        // trailing side. `tapTargetSize` stays at the theme's `padded`, which
        // gives the finger its horizontal 48 without drawing it.
        minimumSize: const Size(0, AppSpacing.minimumTouchTarget),
        alignment: AlignmentDirectional.centerStart,
      ),
      // Two lines before ellipsis, as `MxActionButton` does. One line
      // ellipsizes a translated label into uselessness at large text scales,
      // and this button is often the only way back to what it reveals.
      child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
