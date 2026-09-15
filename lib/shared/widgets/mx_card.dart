import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_elevation.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/states/app_interaction_states.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/extensions/theme_context_extension.dart';

/// How much room a card puts between its edge and its content.
///
/// An enum, not an `EdgeInsets`, for the reason `MxActionButton` takes no
/// `Size`: an open parameter is a per-call-site decision, and the inventory
/// that closed this API found nine spellings of what were three intents.
enum MxCardPadding {
  /// The child owns the whole content area — a card whose content reaches the
  /// edge (a progress track seated on the base, a tile that draws its own
  /// regions), or one whose inner rhythm is not uniform and is therefore the
  /// caller's layout, stated with layout primitives inside [MxCard.child].
  none,

  /// A dense panel — option cards, info panels, feedback bands.
  compact,

  /// The default reading card.
  standard,
}

/// What a selected card paints beyond its `secondary` edge.
///
/// [MxCard.isSelected] owns the edge and the announcement everywhere (M99.70);
/// this decides only whether the *fill* joins in. Not a bool, because the two
/// values are two meanings, not on/off.
enum MxCardSelectionTreatment {
  /// The edge alone. Right for a single-choice picker, where one option is
  /// picked at a time and the border is enough to find it.
  edge,

  /// Edge plus a `semantic.surfaceSelected` fill — for a multi-select list,
  /// where a scanning eye has to catch several picked rows a border alone
  /// would let slide. (It said `secondaryContainer` until M100.35; that has
  /// not been the fill since M99.98, which moved it because the M3 container
  /// was chroma 0.0084 — grey, and *darker* than the rows it marked.)
  tint,
}

/// The state a recessed card wears on its edge.
///
/// Closed and owned by [MxCard.recessed], because that recipe is the one whose
/// edge carries state: the study answer surface shows where typing goes and
/// how the turn was graded. Each member has a production caller; a tone
/// without one is added with its caller, not before (AD-14).
enum MxCardRecessedEdge {
  /// The resting hairline.
  none,

  /// The surface hosts a focused text input, so the card wears the focus-ring
  /// colour at hairline weight — the field's focus made visible at the edge
  /// the user is looking at.
  focus,

  /// The graded turn was right.
  success,

  /// The graded turn was wrong.
  danger,
}

/// Which meaning a feedback card carries.
///
/// Only [danger] exists because only failure bands exist in production.
/// AD-14 derives a role's container when a real caller lands, not before —
/// success/warning/info containers have no token yet, so a tone here without
/// a caller would be a colour waiting for a meaning.
enum MxCardFeedbackTone {
  /// A failure the user must read: an error band with an icon and a message.
  /// The icon and the copy stay product content — the recipe owns only the
  /// surface, so colour is never the sole cue.
  danger,

  /// Something the user should know and can act on, that has not failed —
  /// a permission the OS refused, a reminder that will not fire until it is
  /// granted. `warningContainer`, the pair `AppSemanticColors` kept for
  /// exactly this band (A20.1 P1-13).
  warning,
}

/// The surface a recipe fills with, named as a role.
enum _MxCardFill { surface, recessed, muted, tonal, feedback }

/// The edge a recipe rests at, named as a role.
/// The edge a recipe rests at, named as a role.
///
/// `option` was `control` until M100.2, and the rename came with the token: an
/// option card had been borrowing the *input* border, which a recorded rule
/// keeps untinted because a text field is canvas. A card is not canvas.
enum _MxCardRestingEdge { subtle, option, accent }

/// One recipe, one spec. Private and immutable: a feature picks a named
/// constructor and everything below — fill, edge, radius, elevation — is this
/// object's answer, not the call site's.
class _MxCardSpec {
  const _MxCardSpec({
    required this.elevation,
    required this.radius,
    this.fill = _MxCardFill.surface,
    this.edge = _MxCardRestingEdge.subtle,
  });

  final double elevation;
  final double radius;
  final _MxCardFill fill;
  final _MxCardRestingEdge edge;
}

/// The app's card: a bordered surface whose whole visual grammar lives here.
///
/// **Every constructor is a meaning, and the API holds no visual primitive.**
/// A caller chooses what the card *is* — flat, raised, focal, recessed,
/// feedback, muted, tonal, accent, tile, option — plus content and behaviour;
/// fill, border, radius, elevation, shadow and internal padding are each
/// recipe's private spec. This closed the escape hatches the M99.70 pass left
/// open (`color:`, `borderColor:`, `radius:`, `elevation:`, `EdgeInsets`),
/// which is the same argument `MxActionButton` opens with: the moment a caller
/// can pass a colour, the design system stops being enforceable.
///
/// **Each mode paints depth in its own idiom, by measurement** (AD-14). Light
/// draws Tokyo's two-layer shade. Dark cannot: its page is at L\* 4.11 and the
/// darkest ink in the palette is L\* 1.18, so a shade there has under three
/// L\* to work in. It draws a crisp `outlineVariant` hairline instead, and
/// above `card` adds a real drop — see [shadowsFor]. What it no longer draws,
/// since M100.35, is the bright blurred rim that made a resting neutral card
/// glow. The *role* is the same in both modes either way (M100.33); only the
/// paint differs.
///
/// [onTap] makes the whole surface one target rather than requiring a nested
/// button. **A tappable card may still hold its own controls**: the ink covers
/// the whole card and a nested button wins the gesture arena over it, so a
/// card with a trailing menu does not have to make a *region* of itself the
/// target.
///
/// **The ink layer sits inside the decoration, not around it.** An `InkWell`
/// paints its splash and its hover highlight *before* it paints its child, so
/// a card that wrapped the whole `DecoratedBox` in one drew every state
/// underneath an opaque surface colour. The `Material` is transparent and
/// hosts only the ink; the ripple is clipped to the same radius the border
/// uses.
///
/// **Every interaction state is declared.** `AppInteractionStates.cardOverlay`
/// carries hover, press and the focus wash; keyboard focus additionally
/// thickens the card's own border to the focus ring — painted on the border
/// box, so the card is the same size focused as it is at rest. The ring is
/// drawn only in `FocusHighlightMode.traditional`: focus that arrives without
/// a keyboard (a programmatic move on a touch screen) must not leave a
/// keyboard affordance behind, which is the rule `MxActionButton.shouldAutofocus`
/// already follows (M99.75).
class MxCard extends StatefulWidget {
  /// The flat bordered panel: a card *inside* another surface, or a row in a
  /// flat list column.
  ///
  /// Named at M99.70, because it is not the exception — seventeen call sites
  /// were spelling `elevation: AppElevation.none` by hand. The rule they were
  /// each restating lives here once: a shadow stacked on a shadow reads as a
  /// rendering fault rather than depth, so a card nested in a sheet, a dialog
  /// or another card sits flat.
  ///
  /// **"…and lets its hairline carry the edge" is no longer true, and that
  /// narrowed this recipe sharply** (M99.94). With the hairline gone, a flat
  /// card on a page has one cue left — 2.02 L\* of fill against the page —
  /// where the reference concept gives every page-level card **4.48**: the same
  /// 2.02 above it *plus* a shadow that darkens the page beneath it by 2.46.
  /// Measured on a device, half the cue is not half as clear; it is a list of
  /// panels a reader has to hunt for.
  ///
  /// So `.flat` is now for what its own sentence always said and what M99.26
  /// over-applied: a card **inside another surface** — the import wizard's
  /// step panels, the export sheet's blocks. A card on a scrolling page takes
  /// `.raised`.
  const MxCard.flat({
    required this.child,
    this.padding = MxCardPadding.standard,
    this.isSelected,
    MxCardSelectionTreatment selectionTreatment = MxCardSelectionTreatment.edge,
    this.onTap,
    this.onLongPress,
    super.key,
  }) : _spec = const _MxCardSpec(
         elevation: AppElevation.none,
         radius: AppRadius.lg,
       ),
       // Not an initializing formal: the field is private so a caller cannot
       // read the spec back, while the parameter has to be public to be named.
       // ignore: prefer_initializing_formals
       _selectionTreatment = selectionTreatment,
       _recessedEdge = MxCardRecessedEdge.none,
       _tone = null;

  /// The raised surface: a card that separates itself from the page it sits
  /// on. What the unnamed constructor used to be, named — a default that is a
  /// meaning deserves the same spelling every other meaning gets.
  const MxCard.raised({
    required this.child,
    this.padding = MxCardPadding.standard,
    this.isSelected,
    MxCardSelectionTreatment selectionTreatment = MxCardSelectionTreatment.edge,
    this.onTap,
    this.onLongPress,
    super.key,
  }) : _spec = const _MxCardSpec(
         elevation: AppElevation.card,
         radius: AppRadius.lg,
       ),
       // Not an initializing formal: the field is private so a caller cannot
       // read the spec back, while the parameter has to be public to be named.
       // ignore: prefer_initializing_formals
       _selectionTreatment = selectionTreatment,
       _recessedEdge = MxCardRecessedEdge.none,
       _tone = null;

  /// The focal surface a whole screen is built around: a study prompt.
  ///
  /// [AppRadius.xl] because a card filling the screen reads tighter at the
  /// same corner as a list row does, and [AppElevation.raised] because the
  /// prompt is deliberately lifted above its neighbours. Informational only —
  /// the study screens' controls are their own widgets, so the recipe grows a
  /// tap the day a focal caller has one.
  const MxCard.focal({
    required this.child,
    this.padding = MxCardPadding.standard,
    super.key,
  }) : _spec = const _MxCardSpec(
         elevation: AppElevation.raised,
         radius: AppRadius.xl,
       ),
       isSelected = null,
       _selectionTreatment = MxCardSelectionTreatment.edge,
       _recessedEdge = MxCardRecessedEdge.none,
       _tone = null,
       onTap = null,
       onLongPress = null;

  /// The surface one step *down* from its surroundings: the study answer area,
  /// where content is awaited, hidden or typed. `surfaceContainerLow` under
  /// the focal card's corner, flat — the pair only reads as a pair because
  /// this one steps back.
  ///
  /// [edge] is the one card edge that carries state, and it is closed: see
  /// [MxCardRecessedEdge].
  const MxCard.recessed({
    required this.child,
    this.padding = MxCardPadding.standard,
    MxCardRecessedEdge edge = MxCardRecessedEdge.none,
    super.key,
  }) : _spec = const _MxCardSpec(
         elevation: AppElevation.none,
         radius: AppRadius.xl,
         fill: _MxCardFill.recessed,
       ),
       isSelected = null,
       _selectionTreatment = MxCardSelectionTreatment.edge,
       _recessedEdge = edge,
       _tone = null,
       onTap = null,
       onLongPress = null;

  /// A feedback band the user must read — six error bands used to build this
  /// exact card by hand (`errorContainer`, flat, compact padding), each inside
  /// its own `Semantics(liveRegion:)`. The recipe owns the surface; the icon,
  /// the copy and the live region stay with the caller, so the meaning is
  /// never carried by colour alone.
  const MxCard.feedback({
    required this.child,
    required MxCardFeedbackTone tone,
    super.key,
  }) : _spec = const _MxCardSpec(
         elevation: AppElevation.none,
         radius: AppRadius.lg,
         fill: _MxCardFill.feedback,
       ),
       padding = MxCardPadding.compact,
       isSelected = null,
       _selectionTreatment = MxCardSelectionTreatment.edge,
       _recessedEdge = MxCardRecessedEdge.none,
       onTap = null,
       onLongPress = null,
       // Same shape as `selectionTreatment` above: private field, public name.
       // ignore: prefer_initializing_formals
       _tone = tone;

  /// A quiet informational panel — helper copy beside the content it explains,
  /// on `surfaceContainerHigh` so it reads as an aside rather than a card of
  /// content. The import wizard's info panels are the callers.
  ///
  /// **`elevation: none`, and it used to be `card`** (M99.95). The argument
  /// for the shadow was that `surfaceContainerHigh` is one shallow step off
  /// `surface` and would read as a faint re-tint without a lift. But the fill
  /// is **3.16 L\* below the page**, not above it, so the card said "lifted"
  /// with its shadow and "sunken" with its tone at the same time. Visible on
  /// `card_import_source_light`: the note band cast a shadow while the content
  /// panel above it — the thing it annotates — cast none, which is emphasis
  /// upside down, and is the same "two competing depths" fault M99.92's own
  /// audit caught one recipe over.
  ///
  /// An aside does not need lifting. The tone step alone is what says aside.
  const MxCard.muted({required this.child, super.key})
    : _spec = const _MxCardSpec(
        elevation: AppElevation.none,
        radius: AppRadius.lg,
        fill: _MxCardFill.muted,
      ),
      padding = MxCardPadding.compact,
      isSelected = null,
      _selectionTreatment = MxCardSelectionTreatment.edge,
      _recessedEdge = MxCardRecessedEdge.none,
      _tone = null,
      onTap = null,
      onLongPress = null;

  /// An emphasized callout on `semantic.surfaceEmphasis` — the same
  /// one-step-quieter emphasis `MxActionButton`'s tonal variant carries, on a
  /// surface: a panel the screen wants noticed without out-weighing the page's
  /// own action. Study Home's resume callout is the caller.
  ///
  /// **The name is `tonal` and it is correct; the doc was not.** This said
  /// `secondaryContainer` until M100.35, which is what it painted until
  /// M99.98 — that milestone moved the fill because M3's container measured
  /// chroma 0.0084 in light, effectively neutral, and sat 5.24 L\* below the
  /// page: the screen's primary callout was the greyest thing on it.
  /// `surfaceEmphasis` is 1.11 below the page at 3.6× the chroma. A tonal
  /// surface is still exactly what this is, so M100.35's audit corrected the
  /// sentence rather than the recipe (see `docs/design-system/card-recipes.md`).
  const MxCard.tonal({
    required this.child,
    this.padding = MxCardPadding.standard,
    super.key,
  }) : _spec = const _MxCardSpec(
         elevation: AppElevation.none,
         radius: AppRadius.lg,
         fill: _MxCardFill.tonal,
       ),
       isSelected = null,
       _selectionTreatment = MxCardSelectionTreatment.edge,
       _recessedEdge = MxCardRecessedEdge.none,
       _tone = null,
       onTap = null,
       onLongPress = null;

  /// The accent-edged hero panel: raised, with `borderAccent` carrying the
  /// emphasis a fill would overdo. The deck level summary is the caller.
  const MxCard.accent({
    required this.child,
    this.padding = MxCardPadding.standard,
    super.key,
  }) : _spec = const _MxCardSpec(
         elevation: AppElevation.raised,
         radius: AppRadius.lg,
         edge: _MxCardRestingEdge.accent,
       ),
       isSelected = null,
       _selectionTreatment = MxCardSelectionTreatment.edge,
       _recessedEdge = MxCardRecessedEdge.none,
       _tone = null,
       onTap = null,
       onLongPress = null;

  /// A small card at the control corner ([AppRadius.md]) for a dense item row —
  /// the card-detail history event is the caller. A list-row card at the card
  /// corner reads as a shrunken panel; at the control corner it reads as an
  /// item.
  ///
  /// **It lifts, and it used to be flat** (M99.94). The word in its old first
  /// line was "flat", and while every card carried a hairline that cost it
  /// nothing — the line drew the boundary and the tile was simply the small
  /// one. With the hairline gone this recipe had *neither* cue: 2.15 L\* of
  /// fill against the page and nothing else, on the one screen where the cards
  /// are smallest and most numerous. The study-history timeline was the
  /// complaint that found it, after the same fix had already been made for
  /// every `.flat` caller sitting on a page.
  const MxCard.tile({required this.child, super.key})
    : _spec = const _MxCardSpec(
        elevation: AppElevation.card,
        radius: AppRadius.md,
      ),
      padding = MxCardPadding.compact,
      isSelected = null,
      _selectionTreatment = MxCardSelectionTreatment.edge,
      _recessedEdge = MxCardRecessedEdge.none,
      _tone = null,
      onTap = null,
      onLongPress = null;

  /// A selectable option in a chooser, resting at `borderControl` — because an
  /// option *is* a control, and a control's edge says so before it is picked
  /// (owner review, M99.70: the export sheet keeps the control edge where the
  /// import step keeps the hairline, and both reasons are written down).
  const MxCard.option({
    required this.child,
    // Non-nullable on purpose: an option *is* a control with a selection
    // state, so the tri-state's `null` ("not selectable at all") is not a
    // meaning this recipe can carry — a caller writing `isSelected: null`
    // would get an option that never announces.
    required bool isSelected,
    // **Required, and still nullable** (M100.35). An option is a control, so
    // "no handler" cannot mean "not a control" the way it does on a plain
    // surface — it means *disabled*, and the recipe now renders and announces
    // that. Required because the two are not interchangeable and a caller
    // that omitted the argument was picking one by accident: before this, a
    // null handler left an option looking enabled, announcing its selection,
    // and doing nothing when tapped.
    //
    // Nullable rather than a separate `isEnabled` flag because the disabled
    // state has exactly one production source and it already computes a
    // nullable callback: the export sheet withholds the handler at
    // `CardExportPhase.invalidScope`, where the formats stay readable as the
    // record of what was asked for but can no longer be changed.
    required this.onTap,
    super.key,
  }) : // Not an initializing formal: `this.isSelected` would reopen the
       // nullable tri-state this constructor exists to narrow.
       // ignore: prefer_initializing_formals
       isSelected = isSelected,
       _spec = const _MxCardSpec(
         elevation: AppElevation.none,
         radius: AppRadius.lg,
         edge: _MxCardRestingEdge.option,
       ),
       padding = MxCardPadding.compact,
       _selectionTreatment = MxCardSelectionTreatment.edge,
       _recessedEdge = MxCardRecessedEdge.none,
       _tone = null,
       onLongPress = null;

  final Widget child;

  /// See [MxCardPadding]. Recipes whose density is part of their meaning
  /// (feedback, muted, tile, option) fix it instead of exposing it.
  final MxCardPadding padding;

  /// Makes the whole card a target. Null leaves it a plain surface.
  ///
  /// No accompanying `semanticLabel`. The card annotates itself as a button —
  /// `Semantics(button:)` over the ink, because an `InkWell` contributes a tap
  /// action and focusability but not the flag — and its children supply the
  /// name: a card whose content is readable text does not need a second one,
  /// and an override would *hide* that content from a screen reader rather
  /// than adding to it.
  final VoidCallback? onTap;

  /// Long-press on the whole surface — the Android gesture for entering a
  /// selection mode. Independent of [onTap]: a long-press-only card still
  /// builds the ink layer, which is the branch the first version of this
  /// dropped — the callback existed and could never fire.
  final VoidCallback? onLongPress;

  /// Whether this card is the picked one, and the card owns what that means:
  /// the border switches to `secondary` and the node announces `selected`.
  ///
  /// **`secondary`, and it is measured, not preferred.** Dark `primary` on
  /// `surface` measures **2.90:1** — under WCAG 1.4.11's 3:1 — while
  /// `secondary` measures 8.77:1 in dark and 7.33:1 in light (M99.70).
  ///
  /// **Tri-state, because "not selected" is only sometimes a fact.** `null`
  /// is a card that is not selectable at all and says nothing. `false` is a
  /// selectable card currently unpicked, and it is announced: in a selection
  /// mode or a single-choice picker the *absence* is half the information a
  /// reader needs. A plain reading card must stay `null`, or every panel in
  /// the app turns into a poll.
  final bool? isSelected;

  final _MxCardSpec _spec;
  final MxCardSelectionTreatment _selectionTreatment;
  final MxCardRecessedEdge _recessedEdge;
  final MxCardFeedbackTone? _tone;

  @override
  State<MxCard> createState() => _MxCardState();
}

class _MxCardState extends State<MxCard> {
  /// Only ever true on an interactive card: an `InkWell` is the one thing here
  /// that can take focus, and it is built only when the card has a callback.
  bool _isFocused = false;

  bool get _isInteractive => widget.onTap != null || widget.onLongPress != null;

  @override
  void initState() {
    super.initState();
    // The ring is keyboard-only, and the mode can change while a card is
    // focused (plugging in a keyboard, the first key press). Listening is what
    // keeps the ring honest in both directions rather than only at the next
    // focus change. Interactive cards only: a list of fifty plain panels must
    // not pay fifty listeners for an event none of them can ever act on.
    if (_isInteractive) {
      FocusManager.instance.addHighlightModeListener(_onHighlightModeChanged);
    }
  }

  @override
  void didUpdateWidget(MxCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasInteractive =
        oldWidget.onTap != null || oldWidget.onLongPress != null;
    if (wasInteractive == _isInteractive) return;

    if (_isInteractive) {
      FocusManager.instance.addHighlightModeListener(_onHighlightModeChanged);
      return;
    }
    FocusManager.instance.removeHighlightModeListener(_onHighlightModeChanged);
    // The InkWell is unmounted before it can report the blur, so the fact is
    // reset here — a panel must not keep the ring the control left behind.
    _isFocused = false;
  }

  @override
  void dispose() {
    // Registered iff currently interactive — didUpdateWidget maintains the
    // invariant on every transition.
    if (_isInteractive) {
      FocusManager.instance.removeHighlightModeListener(
        _onHighlightModeChanged,
      );
    }
    super.dispose();
  }

  void _onHighlightModeChanged(FocusHighlightMode mode) {
    if (!_isFocused) return;
    setState(() {});
  }

  void _onFocusChanged(bool isFocused) {
    if (isFocused == _isFocused) return;
    setState(() => _isFocused = isFocused);
  }

  /// Keyboard focus only, on an interactive card only. Focus that arrived
  /// from a pointer or from a programmatic move on a touch screen draws no
  /// ring — the same gate `MxActionButton._takesFocus` applies, for the same
  /// reason: a keyboard affordance without a keyboard makes one control read
  /// as a different component (M99.75). The `_isInteractive` leg is
  /// belt-and-braces over the `didUpdateWidget` reset: a plain panel can
  /// never wear a ring even if the focus fact went stale.
  bool get _isFocusVisible =>
      _isInteractive &&
      _isFocused &&
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  /// **Dark has no shadow to carry elevation (see [shadowsFor]), so a
  /// surface-fill card at `card`/`raised` needs a second cue or it prints
  /// identically to a flat one.** `raised`, `focal` and `accent` all default
  /// to `_MxCardFill.surface`, which used to resolve to `scheme.surface` at
  /// every elevation — the same fill, the same border, the same radius as
  /// `.flat` picks for two of the three, so in dark `.raised` and `.flat`
  /// were the same rendered box.
  ///
  /// **`surfaceContainer`, not a new colour.** It is already one rung of the
  /// ladder `.recessed` and `.muted` read from, sitting lighter than
  /// `surface` in dark by construction — `#221E44` against `#1A1838`
  /// (`app_material_roles.dart`) — which is the direction Material's own
  /// dark-elevation convention lifts a surface: nearer the light, not
  /// farther. `surfaceContainerLow` was not a candidate: `.recessed` already
  /// spends it on the opposite meaning, one step *down*, and a colour
  /// carrying "sunken" on one recipe and "raised" on another would be the
  /// kind of ambiguity this file argues against everywhere else.
  ///
  /// **Light keeps `scheme.surface` unconditionally.** The shadow already
  /// separates elevation there — see [shadowsFor]'s own alpha derivation —
  /// so stepping the fill too would be a second mechanism answering a
  /// question already settled, and every light golden stays untouched.
  /// Whether this is an [MxCard.option] whose handler was withheld.
  ///
  /// The only recipe that can be disabled, because it is the only one whose
  /// meaning *is* "a control you pick". Every other recipe with a null
  /// `onTap` is simply a surface, which is a legitimate thing to be.
  bool get _isDisabledOption =>
      widget._spec.edge == _MxCardRestingEdge.option && widget.onTap == null;

  Color _fillColor(BuildContext context, ColorScheme scheme) {
    final semantic = context.semanticColors;
    // Ahead of the selection tint: a disabled option may still be the picked
    // one — the export sheet keeps showing which format was chosen — and
    // "picked" must not out-shout "you cannot change this".
    if (_isDisabledOption) return semantic.disabledSurface;
    if ((widget.isSelected ?? false) &&
        widget._selectionTreatment == MxCardSelectionTreatment.tint) {
      return semantic.surfaceSelected;
    }

    return switch (widget._spec.fill) {
      _MxCardFill.surface => scheme.surfaceContainerLow,
      _MxCardFill.recessed => scheme.surfaceContainerLowest,
      _MxCardFill.muted => scheme.surfaceContainerHigh,
      _MxCardFill.tonal => semantic.surfaceEmphasis,
      // Exhaustive over the tone so a second tone fails the build here
      // rather than silently rendering as danger.
      _MxCardFill.feedback => switch (widget._tone!) {
        MxCardFeedbackTone.danger => scheme.errorContainer,
        MxCardFeedbackTone.warning => semantic.warningContainer,
      },
    };
  }

  /// The edge a card wears at rest, or **null for no edge at all**.
  ///
  /// **`subtle` now means "no line", and that is the whole of M99.94.** Every
  /// card in this app drew a `borderSubtle` hairline — 1.45:1 on its own fill
  /// in light — so a screen of cards read as a stack of frames rather than a
  /// stack of surfaces. The reference concept the owner supplied draws **no
  /// border on a neutral card**: a vertical scan across a card edge there goes
  /// page → fill in a single pixel, and the card is separated by being pure
  /// white on a page that carries a lavender tint, plus a soft shadow beneath.
  ///
  /// Its fill step is **2.02 L\*** against this app's **2.15** — so the line
  /// was never buying separation the fill did not already have. It was buying
  /// a frame.
  ///
  /// **What still draws one**, because in each case the line is the meaning
  /// rather than the container: the focus ring, a selected card, `.recessed`
  /// while it carries a graded or focused state, `.option` (an option *is* a
  /// control, and a control's edge says so before it is picked) and `.accent`
  /// (the edge is the entire recipe).
  ///
  /// `.feedback` loses its line here too, and that is a smaller decision than
  /// it looks: its hairline was the same neutral grey, on a fill that already
  /// announces itself by hue. The concept gives its feedback panels an edge
  /// *tinted to the fill* — `#CDE4DA` on `#EDF6F3` — which this app has no
  /// token for. Adding one is a palette decision, not this change.
  Color? _restingEdgeColor(BuildContext context) {
    final semantic = context.semanticColors;
    final colors = context.colors;
    // Same precedence argument as the fill, and the same token pair the
    // buttons use for the state (`disabledSurface` / `onDisabled`), so a
    // disabled option reads as the app's disabled and not as a card variant.
    if (_isDisabledOption) return semantic.onDisabled;
    // Precedence below the focus ring: selected > the recipe's stateful edge >
    // the recipe's resting edge. "This is the picked one" outranks a state the
    // recipe painted, which outranks decoration.
    if (widget.isSelected ?? false) return semantic.borderSelected;

    switch (widget._recessedEdge) {
      case MxCardRecessedEdge.focus:
        return colors.primary;
      case MxCardRecessedEdge.success:
        return semantic.success;
      case MxCardRecessedEdge.danger:
        return semantic.danger;
      case MxCardRecessedEdge.none:
        break;
    }

    return switch (widget._spec.edge) {
      _MxCardRestingEdge.subtle => null,
      _MxCardRestingEdge.option => semantic.borderOption,
      _MxCardRestingEdge.accent => semantic.borderAccent,
    };
  }

  EdgeInsetsGeometry get _paddingInsets => switch (widget.padding) {
    MxCardPadding.none => EdgeInsets.zero,
    MxCardPadding.compact => const EdgeInsets.all(AppSpacing.md),
    MxCardPadding.standard => const EdgeInsets.all(AppSpacing.lg),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final radius = widget._spec.radius;
    // **No border at rest, and the fake one is gone** (M100.33).
    //
    // A card with no state to show drew `Border.all(color: fill)` — an
    // invisible line in its own fill — on the argument that
    // `BoxDecoration.border` insets the child, so dropping it would make the
    // content breathe when the focus ring appeared. That is true of
    // `Container`, which adds `decoration.padding` to its child. It is **not**
    // true of `DecoratedBox`, which paints and nothing else; this card has
    // always used `DecoratedBox`, so the border reserved no geometry and the
    // paint bought nothing. `mx_card_interaction_test.dart` proves the bounds
    // now rather than the comment asserting them.
    final fill = _fillColor(context, scheme);
    final restingEdge = _restingEdgeColor(context);
    final decoration = BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadowsFor(widget._spec.elevation, scheme),
    );

    // **The edge paints in front of the child, and focus is a second layer
    // rather than a replacement** (M100.33).
    //
    // Behind the child, an opaque edge-to-edge child covers the card's own
    // state edge — a selected card whose content reaches the corner had no
    // visible selection. And the focus ring used to *replace* the resting edge,
    // so tabbing onto a selected card removed the cue that said it was picked.
    // Both are the same mistake: one channel carrying two facts.
    //
    // The state edge sits on the boundary; the ring is drawn one stroke inside
    // it, so the two are visible at once and neither moves layout — a
    // foreground decoration paints without participating in it.
    final Border? stateEdge = restingEdge == null
        ? null
        : Border.all(color: restingEdge);
    final Border? focusRing = _isFocusVisible
        ? Border.fromBorderSide(AppInteractionStates.focusIndicator(scheme))
        : null;
    // **The card clips what it holds.** Anything a caller seats on an edge —
    // the deck card puts a progress track on its base — is otherwise cut by
    // its own box rather than by the card's corner: a `ClipRRect` around a
    // 4px-tall bar clamps a 16px radius down to 4. Clipping here is the only
    // place that knows the real geometry. `antiAlias`, not `hardEdge`: a
    // curve stepped by whole pixels is visible against a hairline border.
    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Padding(padding: _paddingInsets, child: widget.child),
    );
    // **Order is the whole mechanism, and both layers are unconditional.**
    //
    // The two paint on the same box and neither takes part in layout, so the
    // ring is drawn first and the state edge over it: the ring's outer stroke
    // is covered by the 1 px state line and the rest stays visible just inside.
    // A selected card that takes focus shows both — the selection on the
    // boundary, the ring within it — and the card's bounds, its content bounds
    // and its size are identical in every combination.
    //
    // **They are added whether or not they draw**, and that is not tidiness.
    // Wrapping only when there is something to paint changes the *shape* of the
    // element tree between two builds, so Flutter reparents everything below
    // and every `State` under the card is thrown away and rebuilt. The card
    // that found this holds a `TextField`: taking focus flipped the resting
    // edge on, the wrapper appeared, the field was recreated without its focus,
    // and the keyboard connection was dropped — typing went nowhere and the
    // submit button stayed disabled, with no error anywhere. A `BoxDecoration`
    // whose `border` is null paints nothing, so the constant tree costs a
    // render object and no pixels.
    content = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: focusRing,
      ),
      child: content,
    );
    content = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: stateEdge,
      ),
      child: content,
    );

    final tap = widget.onTap;
    final longPress = widget.onLongPress;
    if (tap == null && longPress == null) {
      final box = DecoratedBox(decoration: decoration, child: content);
      // A disabled option is still a control, and a screen reader has to hear
      // that: `button` with `enabled: false` announces "dimmed", where the
      // plain selected-surface annotation below would have offered a
      // selection with no hint that it cannot be changed.
      if (_isDisabledOption) {
        return Semantics(
          button: true,
          enabled: false,
          selected: widget.isSelected,
          child: box,
        );
      }
      if (widget.isSelected == null) return box;

      return Semantics(selected: widget.isSelected, child: box);
    }

    // `button: true` only when there is a tap — a long-press-only card offers
    // an action, not an activation. An `InkWell` contributes the tap action
    // and focusability but **not** the button flag; annotating rather than
    // labelling is the point, because a `label` here would replace the
    // children's text instead of naming the control.
    return DecoratedBox(
      decoration: decoration,
      child: Semantics(
        button: tap != null,
        // Passed through as the tri-state it is; see [MxCard.isSelected].
        selected: widget.isSelected,
        child: Material(
          // Transparency rather than a colour: the `DecoratedBox` around it
          // already paints the surface, and a second opaque layer would double
          // the border radius' antialiasing seam.
          type: MaterialType.transparency,
          child: InkWell(
            onTap: tap,
            onLongPress: longPress,
            onFocusChange: _onFocusChanged,
            // One property for hover, press and focus, so the three cannot be
            // set from three different places. It also clips to the card's own
            // corner, because `borderRadius` below governs the whole ink layer.
            overlayColor: AppInteractionStates.cardOverlay(scheme),
            borderRadius: BorderRadius.circular(radius),
            // A pressable thing is a target: 48 is the floor every control in
            // this app keeps, and it must be structural rather than an
            // accident of the padding.
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppSizing.touchTarget,
                minHeight: AppSizing.touchTarget,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
