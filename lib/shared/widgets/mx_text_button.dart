import 'package:flutter/material.dart';

import '../../core/theme/components/app_button_themes.dart';
import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/foundations/app_stroke.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/extensions/app_ink.dart';

/// A low-emphasis action drawn as a bare label.
///
/// The third weight, under `MxActionButton`'s filled and outlined variants: an
/// action that belongs in the flow of the content rather than beside it —
/// *Show today's summary* is the first, and the one it was built for.
///
/// **The link's geometry and colours live in the theme.** `buildTextButtonTheme`
/// owns the zero padding, the 48 height floor, the suppressed overlay and the
/// state-blended foreground — see `app_button_themes.dart` for why each is what
/// it is. What this widget adds is the two things a `ButtonStyle` cannot carry:
///
/// **The underline rides the label, never the button.** A decoration on the
/// button's shared style inherits into the icon glyphs — the kit had exactly
/// that bug, an underlined `expand_more` — so the label alone carries it,
/// through `.copyWith` on the style the button already resolved: hover
/// underlines, focus underlines at twice the font's stroke. (The kit also
/// offsets the underline 3px from the baseline; `TextStyle` has no underline
/// offset, and the font's own position is the accepted divergence.)
///
/// **Destructive is the same link with `danger` as its accent** —
/// [textLinkForeground] with a different pair, danger as a LABEL, not as a
/// fill.
class MxTextButton extends StatefulWidget {
  const MxTextButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isDestructive = false,
    this.isCompact = false,
    this.accent,
    this.semanticLabel,
    super.key,
  });

  /// Already-localized. The screen owns the copy; the button never reads ARB.
  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  /// Drawn before the label.
  final IconData? icon;

  /// Drawn after the label — `Icons.expand_more` on the show-summary link.
  final IconData? trailingIcon;

  /// Danger as a label: the text goes `semanticColors.danger`.
  final bool isDestructive;

  /// Drops the label to `label-md`, for a link sharing a row with a heading.
  ///
  /// **Because the row's own heading is `label-md`.** A `TextButton` takes
  /// `label-lg` (14) from Material, and the deck list's heading is 12 — a
  /// control set larger than the thing it names has the hierarchy backwards,
  /// which is the whole defect the sort control was rebuilt to fix. The same
  /// adjustment, and the same reason, as `MxIconButton.isCompact`: only the
  /// glyph or the type moves, never the 48 target.
  final bool isCompact;

  /// What a screen reader announces instead of the painted words.
  ///
  /// **For a link whose label is a value, not an action.** The sort control
  /// paints the order it is in — `Recent` — and a reader hearing "Recent,
  /// button" is told a word and not what pressing it does. The announcement
  /// **contains** the painted label rather than replacing it (WCAG 2.5.3): a
  /// voice-control user says what they can see.
  ///
  /// Null leaves the painted label as the accessible name, which is right
  /// everywhere the words are already the action.
  final String? semanticLabel;

  /// The link's ink, when the surface behind it is not the page.
  ///
  /// **A parameter rather than a `TextButtonTheme` at the call site.**
  /// `TextButtonTheme.of` returns the nearest data and does **not** merge with
  /// the ancestor, so wrapping this button to change one colour silently drops
  /// the rest of `buildTextButtonTheme` — zero padding, a 48 minimum, start
  /// alignment, no splash — and the button then renders 12dp indented, 40 tall,
  /// with a ripple no other text button in the app has. `TextButton.style`
  /// merges; this goes through it, exactly as [isDestructive] does.
  ///
  /// Null keeps `AppInk.accent`, which is `primary` and right on the page.
  ///
  /// **An `AppInk`, not a `Color`** (M100.5). Four features were each passing
  /// `context.colors.onErrorContainer` here by hand — the same value, four
  /// times, because the parameter was a hole rather than a vocabulary. The ink
  /// they all wanted now belongs to `MxFeedbackBand`, which is the widget that
  /// knows what ground its link sits on; this parameter stays for the next
  /// caller with a real reason, but it can only name a token.
  final AppInk? accent;

  @override
  State<MxTextButton> createState() => _MxTextButtonState();
}

class _MxTextButtonState extends State<MxTextButton> {
  /// Owned here so the label can re-style itself on the same hover/focus/press
  /// facts the button resolves its colours from — one source for both.
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  /// The theme's resolver with a different accent — the same link, a different
  /// pair. Null when neither is asked for, so `textButtonTheme` applies
  /// untouched.
  ButtonStyle? _accentStyle(BuildContext context) {
    final AppInk? accent = widget.isDestructive ? AppInk.danger : widget.accent;
    if (accent == null) return null;

    final foreground = textLinkForeground(
      context.colors,
      context.semanticColors,
      accent: accent.resolve(context),
    );

    return ButtonStyle(foregroundColor: foreground, iconColor: foreground);
  }

  /// The accent style, plus the compact rung when one is asked for.
  ///
  /// Merged rather than replaced: `TextButton.style` merges into
  /// `textButtonTheme`, so naming a `textStyle` here leaves the zero padding,
  /// the 48 floor and the state-blended foreground exactly where they were.
  ButtonStyle? _style(BuildContext context) {
    final accent = _accentStyle(context);
    if (!widget.isCompact) return accent;

    final compact = ButtonStyle(
      textStyle: WidgetStatePropertyAll<TextStyle?>(context.texts.labelMedium),
    );

    return accent == null ? compact : accent.merge(compact);
  }

  @override
  Widget build(BuildContext context) {
    final button = _button(context);
    final name = widget.semanticLabel;
    if (name == null) return button;

    // **One node, carrying everything the button's node did.** The trap is the
    // one `MxActionButton` documents: `Semantics(label:) + ExcludeSemantics`
    // drops the button's own node and — without `container` — does not
    // reliably put one back, so the control announces as loose text rather
    // than as a button. Role, enabled state and the tap action are restated.
    return Semantics(
      container: true,
      button: true,
      enabled: widget.onPressed != null,
      focusable: widget.onPressed != null,
      label: name,
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: button,
    );
  }

  Widget _button(BuildContext context) {
    return TextButton(
      statesController: _states,
      onPressed: widget.onPressed,
      style: _style(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: <Widget>[
          if (widget.icon != null) Icon(widget.icon, size: AppIconSize.sm),
          Flexible(
            child: _StateStyledLabel(states: _states, label: widget.label),
          ),
          if (widget.trailingIcon != null)
            Icon(widget.trailingIcon, size: AppIconSize.sm),
        ],
      ),
    );
  }
}

/// The label, restyled as the button's interaction states change.
class _StateStyledLabel extends StatelessWidget {
  const _StateStyledLabel({required this.states, required this.label});

  final WidgetStatesController states;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: states,
      builder: (context, _) {
        final value = states.value;
        final isFocused = value.contains(WidgetState.focused);
        final isHovered = value.contains(WidgetState.hovered);

        // `copyWith` on the style the button resolved, so colour and typography
        // stay the button's business and only the decoration is added here.
        // `decorationColor` is set explicitly to the label's own colour: left
        // null, the engine falls back to a default that does not track the
        // state-blended foreground, and the underline visibly disagrees with
        // the text it belongs to.
        final base = DefaultTextStyle.of(context).style;
        final style = isFocused || isHovered
            ? base.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: base.color,
                // The same stroke every other focus indicator in the app draws
                // — a text button has no border to thicken, so the underline
                // carries it.
                decorationThickness: isFocused ? AppStroke.focus : null,
              )
            : base;

        // Two lines before ellipsis, as `MxActionButton` does. One line
        // ellipsizes a translated label into uselessness at large text scales,
        // and this button is often the only way back to what it reveals.
        return Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }
}
