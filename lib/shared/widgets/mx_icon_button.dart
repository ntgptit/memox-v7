import 'package:flutter/material.dart';

import '../../core/theme/components/actions/app_icon_button_theme.dart';
import '../../core/theme/foundations/app_icon_size.dart';
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
  /// raised flag. `AppSemanticColors.warningInk` — a glyph is read like a word,
  /// so it takes the warning ink rather than the handoff's fill, which reads
  /// 2.15:1 on the card (M100.87). The same family the tone axis on dialogs
  /// uses for the same meaning.
  ///
  /// **It is never the only signal.** The glyph itself changes with the state —
  /// outlined to filled — so the flag reads as raised without colour vision,
  /// and the accessible name says which way the next tap goes.
  warning,
}

/// How much of an edge an icon button draws around itself.
///
/// **A second axis, not a second widget.** [MxIconButtonTone] says what the
/// glyph *means*; this says how much the control asks to be noticed as a
/// control. They are independent — a warning glyph in an outlined well is a
/// coherent thing — so folding them into one enum would multiply values to
/// state a product.
enum MxIconButtonShape {
  /// No edge. The bar's ink on the bar's ground, which is every caller that
  /// sits inside a surface already reading as a bar.
  plain,

  /// A hairline circle on the app's surface. For a bar whose actions sit over
  /// the page rather than inside a chrome band, where a bare glyph on a tinted
  /// ground has nothing to separate it from the content behind it.
  outlined,
}

/// Where the button sits, which decides its glyph (D16): the handoff's
/// IconButton draws 20; its Foundations give app-bar and navigation actions 24.
enum MxIconButtonPlacement {
  /// Rows, cards, fields, sheets — everything that is not the top bar.
  content,

  /// An action in the screen's app bar, or in the contextual bar that stands in
  /// for it during selection.
  bar,
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
/// Size comes from `IconButtonThemeData`: a 36 ink circle inside a 48 target.
/// [placement] is the one adjustment, and it moves the **glyph**, never the
/// circle or the target — 20 in content, 24 in a bar (D16).
class MxIconButton extends StatelessWidget {
  const MxIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.tooltip,
    this.placement = MxIconButtonPlacement.content,
    this.tone = MxIconButtonTone.standard,
    this.shape = MxIconButtonShape.plain,
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

  /// Where the button sits: [MxIconButtonPlacement.bar] keeps the
  /// Foundations' 24 glyph for app-bar actions; everything else draws the
  /// handoff IconButton's 20.
  final MxIconButtonPlacement placement;

  /// What the glyph means. [MxIconButtonTone.standard] keeps the theme's ink,
  /// which is every existing caller.
  final MxIconButtonTone tone;

  /// Whether the control draws its own edge. [MxIconButtonShape.plain] keeps
  /// the theme's borderless style, which is every existing caller.
  final MxIconButtonShape shape;

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
      // Null for `plain`, so the theme's own style stands untouched: a style
      // object here merges over the theme, and passing an empty one would
      // still be a merge nobody asked for.
      style: switch (shape) {
        MxIconButtonShape.plain => null,
        MxIconButtonShape.outlined => buildOutlinedIconButtonStyle(
          context.colors,
          context.semanticColors,
        ),
      },
      // Null keeps `iconButtonTheme`'s foreground. `IconButton` folds a
      // non-null `color` into a style that still resolves disabled through
      // `disabledColor`, so a toned button greys out like every other one —
      // the tone speaks about the *state the icon reports*, not about whether
      // the control can be pressed.
      color: switch (tone) {
        MxIconButtonTone.standard => null,
        MxIconButtonTone.warning => context.semanticColors.warningInk,
      },
      tooltip: tooltip ?? semanticLabel,
      icon: Icon(
        icon,
        size: switch (placement) {
          MxIconButtonPlacement.content => AppIconSize.sm,
          MxIconButtonPlacement.bar => AppIconSize.md,
        },
        semanticLabel: semanticLabel,
      ),
    );
  }
}
