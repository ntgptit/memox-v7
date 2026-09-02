import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/extensions/theme_context_extension.dart';

/// What an icon button's glyph *means*, on the one axis a bar action has.
///
/// **An enum rather than a `Color?`.** A colour parameter lets any caller paint
/// any icon any shade, which is how an app ends up with four different oranges
/// and no way to change them together. The card editor's flag was the first
/// caller to need one — a raised flag is a state the user set, and it has to be
/// visible as a state — and it reached for `IconButton(color:)` directly
/// because this widget offered nothing.
enum MxIconButtonTone {
  /// The bar's own ink. Every action that is only an action.
  standard,

  /// A state worth noticing, set by the user and reversible: the card editor's
  /// raised flag. `AppSemanticColors.warning`, the same role the tone axis on
  /// dialogs uses for the same meaning.
  ///
  /// **It is never the only signal.** The glyph itself changes with the state —
  /// outlined to filled — so the flag reads as raised without colour vision,
  /// and the accessible name says which way the next tap goes.
  warning,
}

/// An action with no visible label.
///
/// [semanticLabel] is **required**, and that is the entire reason this widget
/// exists rather than `IconButton`. An icon-only control with no label is a
/// blank button to a screen reader — the user is told there is something
/// tappable and nothing about what it does. Making the label optional means it
/// gets omitted, because omitting it changes nothing anyone can see.
///
/// The label is carried by the `Icon`, not by a `Semantics` wrapper. A wrapper
/// with `excludeSemantics` would take the button's own node with it and lose
/// "button", "enabled" and the tap action; the icon's label merges into that
/// node instead and leaves all three intact.
///
/// Size comes from `AppIconSize` and the 48×48 minimum from
/// `IconButtonThemeData`. [isCompact] is the one adjustment, and it moves the
/// **glyph**, never the target. It exists for the study session's top bar, where
/// the close button shares a row with a progress track that has to read as a
/// measure — see `AppIconSize.mdCompact`.
class MxIconButton extends StatelessWidget {
  const MxIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.tooltip,
    this.isCompact = false,
    this.tone = MxIconButtonTone.standard,
    super.key,
  });

  final IconData icon;

  /// Already-localized. What the action does, not what the glyph looks like.
  final String semanticLabel;

  /// `null` disables the button. A disabled button invokes nothing — Flutter
  /// drops the gesture, so there is no path from a tap to the callback.
  final VoidCallback? onPressed;

  /// Already-localized. Only when the visible hover/long-press text should read
  /// differently from [semanticLabel]; otherwise the label serves both and the
  /// two cannot drift apart.
  final String? tooltip;

  /// Drops the glyph to [AppIconSize.mdCompact], for a control sharing a row
  /// with something that needs the width.
  ///
  /// **It does not make the button narrower, and it never did.** This used to
  /// constrain the box to 36 wide; Material's tap-target padding re-inflated it
  /// to 48 and centred the 36 inside, so the row spent 48 either way. The
  /// constraint is gone rather than fixed — 48 is [AppSizing.touchTarget]
  /// and shrinking below it fails `androidTapTargetGuideline`, which
  /// `study_accessibility_test.dart` asserts. A row that needs its leading glyph
  /// closer to the screen edge than 14px has to be laid out edge-to-edge; see
  /// `MxSessionTopBar`.
  final bool isCompact;

  /// What the glyph means. [MxIconButtonTone.standard] keeps the theme's ink,
  /// which is every existing caller.
  final MxIconButtonTone tone;

  // A filled variant existed here once (`isFilled`, for a Library mockup) and
  // was removed twice over: its one caller went in #328, and its style was
  // `IconButton.styleFrom(backgroundColor:)` — the flat-property spelling
  // whose disabled state stays fully armed and whose press never darkens,
  // the exact divergence `buildFilledStyle` exists to prevent. If a bar ever
  // leads with a filled icon action again, build its colours from the shared
  // resolvers, not from `styleFrom`.
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      // Null keeps `iconButtonTheme`'s foreground. `IconButton` folds a
      // non-null `color` into a style that still resolves disabled through
      // `disabledColor`, so a toned button greys out like every other one —
      // the tone speaks about the *state the icon reports*, not about whether
      // the control can be pressed.
      color: switch (tone) {
        MxIconButtonTone.standard => null,
        MxIconButtonTone.warning => context.semanticColors.warning,
      },
      tooltip: tooltip ?? semanticLabel,
      constraints: isCompact
          ? const BoxConstraints.tightFor(
              width: AppSizing.touchTarget,
              height: AppSizing.touchTarget,
            )
          : null,
      padding: isCompact ? EdgeInsets.zero : null,
      icon: Icon(
        icon,
        size: isCompact ? AppIconSize.mdCompact : AppIconSize.md,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
