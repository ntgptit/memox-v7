import 'package:flutter/material.dart';

import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_interaction_states.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';

/// The app's one raised surface: a bordered panel that carries elevation.
///
/// **It was flat, and that was never a rule.** Two doc comments said the surface
/// ladder worked without a shadow, and two milestones read that as a ban — no AD,
/// no BR, no test behind it, while `docs/checklist.md` asked for an Elevation
/// token nobody built. The project owner has since said the app needs real
/// elevation to separate elements, so it has one.
///
/// **The shadow appears in light and not in dark, by measurement.** The dark page
/// sits at the bottom of the lightness scale, so a shadow there moves it by
/// ΔL\* 0.26 where the surface step already moves it 7.70 — see [shadowsFor].
/// Dark keeps its ladder and its border; light gains a shadow and gives some
/// border back.
///
/// [onTap] makes the whole surface one target rather than requiring a nested
/// button. That is a generic capability, not a feature one: any card that stands
/// for a thing the user can open wants it, and building the ink by hand at each
/// call site is how two call sites end up with different splash radii.
///
/// **A tappable card may still hold its own controls.** The ink covers the whole
/// card and a nested button wins the gesture arena over it, so a card with a
/// trailing menu does not have to make a *region* of itself the target — which is
/// the arrangement that leaves the rest of the card looking tappable and inert.
/// The web kit had to be taught the same thing the hard way: a `<button>` cannot
/// contain a control, so `MxCard` there lays its target under the content rather
/// than becoming one.
///
/// **The ink layer sits inside the decoration, not around it.** An `InkWell`
/// paints its splash and its hover highlight *before* it paints its child, so a
/// card that wrapped the whole `DecoratedBox` in one drew every state underneath
/// an opaque surface colour — a tappable card with no visible feedback at all.
/// The `Material` is transparent and hosts only the ink; the ripple is clipped to
/// the same [radius] the border uses, and the card looks identical when
/// [onTap] is null.
///
/// **Every interaction state is declared, and until this task none of them was.**
/// A bare `InkWell` takes `ThemeData.hoverColor`, `focusColor` and `splashColor`
/// — hardcoded black-and-white washes with no seed in them and no difference
/// between light and dark. `AppInteractionStates.cardOverlay` replaces all three
/// with the kit's `.mx-card__action` values, and keyboard focus additionally
/// thickens the card's own border to [AppStroke.focus] in the accent. That is the
/// same inset ring `.mx-card__action:focus-visible` draws, and it costs no
/// layout: a `DecoratedBox` never insets its child for a border, so the card is
/// the same size focused as it is at rest.
class MxCard extends StatefulWidget {
  const MxCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.elevation = AppElevation.card,
    this.radius = AppRadius.lg,
    this.color,
    this.borderColor,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// The corner, for the one card that wants a different one.
  ///
  /// [AppRadius.xl] is the study card: a surface filling the screen reads
  /// tighter at the same corner as a list row does. Every other caller leaves
  /// this alone, and the four places the radius is used below — border, clip,
  /// ink and focus ring — all read it, so they cannot disagree.
  final double radius;

  /// How far this card sits above the page. [AppElevation.none] returns it to a
  /// flat bordered panel, which is what a card *inside* another surface wants —
  /// a shadow stacked on a shadow reads as a rendering fault rather than depth.
  final double elevation;

  /// The card's surface, when it must not be `surface`.
  ///
  /// Null is the answer almost everywhere. It exists for a screen holding two
  /// cards that mean different things — a prompt and the space for an answer —
  /// where the pair only reads as a pair if one of them steps down.
  final Color? color;

  /// The card's hairline, when the edge is carrying a state.
  ///
  /// Null is `borderSubtle`, which is every card that is only a card. It exists
  /// for a surface whose *whole* meaning has changed — `fill`'s answer card once
  /// the turn is graded, where the verdict belongs to the card the learner typed
  /// into rather than to a panel drawn inside it. A semantic role from
  /// `AppSemanticColors`, the same way [color] takes a role from `ColorScheme`:
  /// a caller passing an arbitrary colour would be inventing a second card
  /// style, which is the thing this widget exists to prevent.
  ///
  /// Keyboard focus still wins — a focused tappable card draws its focus ring
  /// over this, because "you are here" outranks "this is how it went".
  final Color? borderColor;

  /// Makes the whole card a target. Null leaves it a plain surface.
  ///
  /// No accompanying `semanticLabel`. The `InkWell` below already announces the
  /// card as a button and its children supply the name — a card whose content is
  /// readable text does not need a second one, and an override would *hide* that
  /// content from a screen reader rather than adding to it. If a caller ever has
  /// a card whose contents genuinely do not name it, that is the point to add it,
  /// with the caller in hand to check the announcement against.
  final VoidCallback? onTap;

  /// Long-press on the whole surface — the Android gesture for entering a
  /// selection mode. Optional and independent of [onTap]: a card may be
  /// tappable without being selectable, and the ink layer already exists.
  final VoidCallback? onLongPress;

  @override
  State<MxCard> createState() => _MxCardState();
}

class _MxCardState extends State<MxCard> {
  /// Only ever true on a tappable card: an `InkWell` is the one thing here that
  /// can take focus, and it is built only when [MxCard.onTap] is non-null.
  bool _isFocused = false;

  void _onFocusChanged(bool isFocused) {
    if (isFocused == _isFocused) return;
    setState(() => _isFocused = isFocused);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    // The focus ring replaces the hairline rather than sitting outside it. Both
    // are painted on the border box, so the swap moves nothing beside the card
    // and nothing inside it.
    final border = _isFocused
        ? Border.fromBorderSide(
            AppInteractionStates.focusRing(context.semanticColors),
          )
        : Border.all(
            color: widget.borderColor ?? context.semanticColors.borderSubtle,
          );
    final decoration = BoxDecoration(
      // **A role, not a colour.** `surface` is the card; a caller passes another
      // *scheme* role when the card is one step down from the surface around it
      // — a study screen's answer area against its prompt, which is how the
      // reader knows one is waiting to be filled and the other is not.
      color: widget.color ?? scheme.surface,
      borderRadius: BorderRadius.circular(widget.radius),
      border: border,
      boxShadow: shadowsFor(widget.elevation, scheme),
    );
    // **The card clips what it holds.** Anything a caller seats on an edge — the
    // deck card puts a progress track on its base — is otherwise cut by its own
    // box rather than by the card's corner: a `ClipRRect` around a 4px-tall bar
    // clamps a 16px radius down to 4, so the bar keeps its full width where the
    // card's surface has already curved inward, and the colour runs past the
    // corner. Clipping here is the only place that knows the real geometry.
    // `antiAlias`, not `hardEdge`: a 16px curve stepped by whole pixels is
    // visible against a hairline border.
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Padding(padding: widget.padding, child: widget.child),
    );

    final tap = widget.onTap;
    if (tap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    // `button: true` and nothing else. An `InkWell` contributes a tap action and
    // focusability but **not** the button flag — a screen reader would read the
    // card's text and never say it can be activated. Annotating rather than
    // labelling is the whole point: adding a `label` here would replace the
    // children's text instead of naming the control, which is the mistake the
    // first version of this made.
    return DecoratedBox(
      decoration: decoration,
      child: Semantics(
        button: true,
        child: Material(
          // Transparency rather than a colour: the `DecoratedBox` around it
          // already paints the surface, and a second opaque layer would double
          // the border radius' antialiasing seam.
          type: MaterialType.transparency,
          child: InkWell(
            onTap: tap,
            onLongPress: widget.onLongPress,
            onFocusChange: _onFocusChanged,
            // One property for hover, press and focus, so the three cannot be
            // set from three different places. It also clips to the card's own
            // corner, because `borderRadius` below governs the whole ink layer.
            overlayColor: AppInteractionStates.cardOverlay(scheme),
            borderRadius: BorderRadius.circular(widget.radius),
            child: content,
          ),
        ),
      ),
    );
  }
}
