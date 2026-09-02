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

  /// The outline of a selection control — a checkbox's box, a switch's track.
  ///
  /// **A fourth value, against this file's own warning, and the exception is
  /// narrow enough to state.** The three above are the kit's, and the drift the
  /// warning guards against is a *per-screen* stroke. This is not one: the kit
  /// draws no checkbox and no switch (see `app_toggle_themes.dart`), so where
  /// it is silent the spec is the next authority, and Material 3 puts both at
  /// **2.0** — `_CheckboxDefaultsM3.side` and `_SwitchDefaultsM3
  /// .trackOutlineWidth`. Following [hairline] there was a transcription of a
  /// value nobody had decided.
  ///
  /// **Why a selection control needs twice a card's stroke.** A hairline is
  /// read along a card's whole edge; a checkbox's box is 18dp square, so the
  /// same weight has a fraction of the length to be seen over. The rule is
  /// proportional, not aesthetic — the smaller the control, the more of it has
  /// to be edge.
  ///
  /// It happens to equal [focus]. That is a coincidence, not a relationship,
  /// which is why it is a separate constant: a focus ring that got heavier
  /// should not silently thicken every checkbox in the app. What the equality
  /// does buy is that focus changes only the colour here, exactly as it does on
  /// an input — see `buildInputDecorationTheme`.
  static const double selectionControl = 2;
}
