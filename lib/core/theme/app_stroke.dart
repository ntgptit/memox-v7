/// Stroke widths.
///
/// Three, because the design declares three — `design_system/tokens/
/// elevation.css` names `--border-hairline`, `--border-input` and
/// `--border-focus` and nothing else draws a line in this app. A fourth would be
/// a per-screen decision, which is the drift this file exists to stop.
///
/// **They were six literals before this file, and that is the whole argument.**
/// `1.5` lived in `_inputBorder`, `2` in `iconButtonTheme.side`, again in the
/// outlined button's focused side, again as `MxTextButton`'s focus underline,
/// and `1` in the divider's thickness *and* its space. Nothing said those were
/// the same three decisions, so changing the focus ring meant finding every copy
/// — and the one that was missed stayed at the old weight, visible only on the
/// screen nobody re-checked.
abstract final class AppStroke {
  /// A border or a divider — `--border-hairline`. The card outline, the
  /// navigation bar's top edge, the app bar's scrolled-under line.
  static const double hairline = 1;

  /// An input's border — `--border-input`. The same in every state: focus
  /// shifts the hue and never the width, because Material's 1→2 jump nudges
  /// whatever is laid out beside the field.
  static const double input = 1.5;

  /// A focus-visible indicator — `--border-focus`. The ring on an icon button,
  /// an outlined button and a tappable card, and the thickness of the underline
  /// a text button focuses with.
  static const double focus = 2;
}
