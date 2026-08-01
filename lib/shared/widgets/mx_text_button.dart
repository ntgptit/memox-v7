import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_stroke.dart';
import '../../core/theme/theme_context_extension.dart';

/// How far the label's colour moves toward the ink on hover, and further on
/// press. Mirrors the kit's `color-mix(… 85%/72%, var(--color-text-primary))`.
///
/// Local rather than in `AppStateOpacity`: those are *state-layer* alphas —
/// a wash painted over a control — and these are blends of the label's own
/// colour. `.mx-textbtn` is the one control in the kit with no surface to wash,
/// so its numbers are its own and are not shared with anything.
const double _kHoverBlend = 0.15;
const double _kPressedBlend = 0.28;

/// A low-emphasis action drawn as a bare label.
///
/// The third weight, under `MxActionButton`'s filled and outlined variants: an
/// action that belongs in the flow of the content rather than beside it —
/// *Show today's summary* is the first, and the one it was built for.
///
/// **It carries no padding, no radius and no hover surface, and that is the
/// entire reason it exists as a widget.** Material's `TextButton` insets its
/// label by 12 and paints a tinted overlay on hover — and a text button with a
/// background is an outlined button with the border turned off. Zero padding
/// puts the label on the same vertical line as everything else in the column;
/// the overlay is suppressed, and every state lives on the text itself: hover
/// blends the colour toward the ink and underlines, focus underlines at twice
/// the font's stroke, press blends further. (The kit also offsets the
/// underline 3px from the baseline; `TextStyle` has no underline offset, and
/// the font's own position is the accepted divergence.)
///
/// **The underline rides the label, never the button.** A decoration on the
/// button's shared style inherits into the icon glyphs — the kit had exactly
/// that bug, an underlined `expand_more` — so the label alone carries it,
/// through `.copyWith` on the style the button already resolved.
///
/// **The 48 floor is kept as height, not as padding.** `AppSpacing` calls the
/// touch target a floor rather than a step for exactly this case: the label
/// may sit flush, but the thing a finger has to hit may not shrink to the
/// height of a line of text.
///
/// **Colour is the accent, not the fill.** `ColorScheme.primary` is held dark
/// enough on dark surfaces that it measures 3.33:1 as bare text and fails AA
/// at label size; `semanticColors.primaryAccent` (dark `#8A8AE0`, 6.26:1) is
/// the variant that reads as a label. Destructive actions carry
/// `semanticColors.danger` — danger as a LABEL, not as a fill.
class MxTextButton extends StatefulWidget {
  const MxTextButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isDestructive = false,
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

  Color _foreground(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return context.semanticColors.onDisabled;
    }

    final accent = widget.isDestructive
        ? context.semanticColors.danger
        : context.semanticColors.primaryAccent;
    final ink = context.colors.onSurface;

    if (states.contains(WidgetState.pressed)) {
      return Color.lerp(accent, ink, _kPressedBlend)!;
    }
    if (states.contains(WidgetState.hovered)) {
      return Color.lerp(accent, ink, _kHoverBlend)!;
    }
    return accent;
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      statesController: _states,
      onPressed: widget.onPressed,
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
        // The width floor is zero rather than Material's 64: a link that pads
        // itself out to a minimum width re-introduces the misalignment on the
        // trailing side. `tapTargetSize` stays at the theme's `padded`, which
        // gives the finger its horizontal 48 without drawing it.
        minimumSize: const WidgetStatePropertyAll<Size>(
          Size(0, AppSpacing.minimumTouchTarget),
        ),
        alignment: AlignmentDirectional.centerStart,
        // No hover surface and no ripple — the states live on the text. A
        // scheme colour at alpha zero rather than the framework's transparent
        // constant, which the token guard rightly reads as hardcoded.
        overlayColor: WidgetStatePropertyAll<Color>(
          context.colors.primary.withAlpha(0),
        ),
        splashFactory: NoSplash.splashFactory,
        foregroundColor: WidgetStateProperty.resolveWith(_foreground),
        iconColor: WidgetStateProperty.resolveWith(_foreground),
      ),
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
