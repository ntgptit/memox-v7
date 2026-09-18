import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_decorations.dart';
import '../../core/theme/foundations/app_durations.dart';
import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_motion_policy.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/foundations/app_stroke.dart';
import '../../core/theme/typography/app_typography.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import 'mx_icon.dart';
import '../../core/theme/extensions/app_ink.dart';

/// The search bar that sits under an app bar.
///
/// **Not `MxTextField`, and the difference is not cosmetic.** That one is a form
/// control: an outline, a floating label, a field you are expected to fill in
/// before continuing. A search bar with a label above it reads as a required
/// step. This is a filled pill with a placeholder and no label at all, which
/// reads as somewhere you *may* type.
///
/// It searches nothing itself — it reports what was typed. Whether that means a
/// flat scan of one level or a walk of a whole subtree is the screen's decision,
/// and the two want different result rows.
///
/// **A custom filled mobile control, not an `InputDecorator` clone.** It keeps
/// its own surface model and its own shape — [AppRadius.md], not a pill, and
/// `border-ghost` ([AppDecorations.hairlineEdge]) at rest / `scheme.primary`
/// focused, both at [AppStroke.hairline] (the v3 SearchField spec, superseding
/// M100.36 4E's pill + `scheme.outline` boundary). No shadow: search is flat,
/// and the fill and the edge each carry a different fact.
///
/// **The resting edge is translucent, on purpose, and the owner chose that
/// figure knowingly.** `border-ghost` measures **1.19:1** against the page in
/// light — nowhere near WCAG 1.4.11's 3:1, the same trade-off already made for
/// `MxTextField`'s enabled border under M100.101 (`app_input_theme.dart`). The
/// field is legible without it: its own fill steps away from the page
/// (`surfaceContainer` at rest, `surfaceContainerLowest` focused) and its text
/// and glyph carry full-strength ink. `scheme.outline`'s M100.36 boundary fix
/// (#433 §4.1) is superseded here, not forgotten — this is the same argument
/// TextField already settled, extended to its sibling control.
///
/// **Focus changes the fill and the border, never a size.** The border is drawn
/// outside the box (`strokeAlignOutside`) so gaining a colour on focus moves
/// nothing beside it — the same rule the form input follows.
///
/// **The name is not the placeholder** (M100.36 4D). A hint disappears the
/// moment the user types — on screen *and* from the semantics tree, because
/// `InputDecorator` wraps it in an `Opacity` at zero — so a search field named
/// by its hint was unnamed for exactly as long as it held a query (#433 F1).
/// [semanticLabel] is required and is the field's name in every state; the
/// visible hint is excluded from semantics so the two are never read twice.
///
/// **It grows with the text, from a floor of [_pillFloorHeight] (52).** The v3
/// SearchField spec states 52 as the field's own height — the foundations task
/// measured the old 48-floor field at 49 by then and explicitly left "whether
/// the floor itself should move to meet it" to this component's spec
/// (`mx_search_field_test.dart`, `48 is a floor` test). The floor stays a
/// *floor*, never a ceiling (#433 F2: `SizedBox` + `expands: true` used to clip
/// the placeholder from `textScaler` 2.5) — only the resting value moved.
/// The inset that brings a one-line field to [_pillFloorHeight] at the default
/// scale: (52 − 20) / 2 = 16, which now lands on [AppSpacing.lg] — a byproduct
/// of the new floor, not a rule computed from it.
const double _fieldInset = (_pillFloorHeight - _lineHeight) / 2;

/// The v3 SearchField spec's own height (`--memox-size-input`, 52) — specific
/// to this control, so it stays local rather than joining `AppSizing`: nothing
/// else in the app renders it (`AppSizing`'s own header rule).
const double _pillFloorHeight = 52;

/// `body-md`'s line at the default scale — 14 × 1.43, rounded as the engine
/// rounds it.
const double _lineHeight = 20; // off-grid: a type metric, not a gap

class MxSearchField extends StatefulWidget {
  const MxSearchField({
    required this.value,
    required this.onChanged,
    required this.hintText,
    required this.semanticLabel,
    required this.clearSemanticLabel,
    this.resultCount,
    this.shouldAutofocus = false,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;

  /// Already-localized, and it should name the **scope**: on a nested level the
  /// user needs to know whether they are searching this deck or everything.
  /// Painted only; the accessible name is [semanticLabel].
  final String hintText;

  /// Already-localized. What a screen reader calls this field, whether it is
  /// empty or holding a query. Required, for the reason `MxTextField` requires
  /// a `label`: a hint is not a name.
  final String semanticLabel;

  /// Already-localized label for the clear button. Required: a `null` here
  /// left the button with no name and no tooltip, and two of three callers
  /// happened to pass one.
  final String clearSemanticLabel;

  /// Shown while there is a query. Omit when the screen does not know yet.
  final int? resultCount;

  /// Focus the field the moment it appears.
  ///
  /// For a field that is *revealed* by a control rather than resting on the
  /// page: the tap that opened it was the request to type, and making the user
  /// tap a second time into the field they just asked for is a step with no
  /// information in it. The HTML kit's `autofocus` attribute, as a parameter.
  final bool shouldAutofocus;

  @override
  State<MxSearchField> createState() => _MxSearchFieldState();
}

class _MxSearchFieldState extends State<MxSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocusChanged);
  bool _hasFocus = false;

  void _onFocusChanged() {
    if (_focusNode.hasFocus == _hasFocus) return;
    setState(() => _hasFocus = _focusNode.hasFocus);
  }

  @override
  void didUpdateWidget(MxSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only when the value genuinely differs — assigning `text` moves the caret
    // to the end, so doing it on every rebuild would fight the user mid-word.
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasQuery = widget.value.isNotEmpty;
    final count = widget.resultCount;
    // **Its own rung, and it is the pill's to own** (M100.36 4P analogue). The
    // form field's hint is `body-lg` because its value is; this pill's value is
    // `body-md` — a search strip under an app bar, not a form — so its
    // placeholder is the same rung, in `onSurfaceVariant`. Stated here rather
    // than read from `inputDecorationTheme.hintStyle`, so the two controls
    // cannot drift apart by one following the other's rung.
    final TextStyle text = context.texts.bodyMedium!;
    // The one restyle a regex could not see — it went through this local
    // (A20.1 P1-07 d). `inked` names the ink; `mx_text_restyle_alias_test`
    // keeps the next alias out.
    final TextStyle hint = text.inked(context, AppInk.quiet);

    return AnimatedContainer(
      // The crossfade between the resting well and the focused surface is
      // decoration on a state change — the state itself is carried by the fill
      // and the border colour, both of which are already correct in the first
      // frame. Reduced motion drops the fade and keeps the state.
      duration: AppMotionPolicy.durationOf(context, AppDurations.fast),
      curve: AppDurations.standard,
      // A floor, as [_pillFloorHeight] names it. The row inside grows with the
      // text, so the pill is 52 at the default scale and taller only when the
      // text needs it.
      constraints: const BoxConstraints(minHeight: _pillFloorHeight),
      decoration: BoxDecoration(
        color: _hasFocus
            ? colors.surfaceContainerLowest
            : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        // `strokeAlignOutside` keeps the stroke out of the layout: a border
        // inside the box would grow the pill past its floor, and at 320 wide
        // with `textScaler` 2.0 the chrome has no two pixels to spare.
        border: Border.all(
          color: _hasFocus
              ? colors.primary
              : AppDecorations.hairlineEdge(colors).color,
          // Stated rather than left to `Border.all`'s own default, on the
          // precedent `AppDecorations.hairlineEdge` already argues: the width
          // is one *because the stroke scale says a hairline is one*.
          // ignore: avoid_redundant_argument_values
          width: AppStroke.hairline,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      // 4 on the trailing side against 16 on the leading one, as the v3 spec
      // has it: the glyph needs room off the edge, the clear button brings its
      // own inset.
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.xs),
      child: Row(
        // **Centre, not stretch.** The design's `align-items: center` aligns the
        // boxes themselves; stretching them made each child centre its own
        // content by its own rules, and a glyph centred in a taller box does
        // not land where a line of text centred in one does.
        children: <Widget>[
          MxIcon(
            Icons.search,
            size: MxIconSize.mdCompact,
            // The glyph tracks the border's hue rather than `AppInk.stated`:
            // `accent` is `primary`'s hue held to text-legible lightness
            // (`AppSemanticColors.accentInk`) — the closest named ink to a raw
            // `primary` read, which the icon-ink guard reserves for a button's
            // own inherited `IconTheme` (`icon_ink_boundary_test.dart`).
            ink: _hasFocus ? AppInk.accent : AppInk.quiet,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Semantics(
              label: widget.semanticLabel,
              textField: true,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.shouldAutofocus,
                onChanged: widget.onChanged,
                textInputAction: TextInputAction.search,
                keyboardType: TextInputType.text,
                style: text,
                decoration: InputDecoration(
                  // Painted, not announced: `semanticLabel` above is the name.
                  hint: ExcludeSemantics(
                    child: Text(
                      widget.hintText,
                      style: hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // The pill *is* the decoration. Left to the theme this would
                  // draw the form field's hairline inside it — and, since
                  // M100.101, the theme's own fill as well.
                  //
                  // **`filled: false` is load-bearing, not tidiness.** v3 gave
                  // `InputDecorationTheme` a fill; this control already paints
                  // one, on the `BoxDecoration` above, and it is the one that
                  // changes on focus. With both, the theme's fill paints
                  // *inside* the pill and covers it: the visual audit caught it
                  // as the pill's declared colour reaching only 8% of its own
                  // rect. A control that supplies its own container opts out of
                  // the theme's.
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  // `isCollapsed`, not `isDense`: dense keeps some of the
                  // decorator's own vertical padding, and that padding is what
                  // biased the text off the glyph's line. The inset is stated
                  // on the field rather than the pill so the clear button's own
                  // 48dp touch target does not add to it (A20.1 P2-17) — the
                  // pill sits at [_pillFloorHeight], the field a few dp inside
                  // it, and Android's target guideline reads the node that
                  // takes the tap, which is the field.
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: _fieldInset,
                  ),
                ),
              ),
            ),
          ),
          // The count and the clear button appear together, and only once
          // something has been typed — an empty field with a clear button on it
          // offers to undo nothing.
          if (hasQuery) ...<Widget>[
            if (count != null) ...<Widget>[
              Text(
                '$count',
                // Through the wght axis — a bare `fontWeight:` paints the
                // rung's old weight.
                style:
                    AppTypography.withWeight(
                          context.texts.labelSmall!,
                          FontWeight.w600,
                        )
                        .inked(context, AppInk.quiet)
                        .copyWith(
                          letterSpacing: AppTypography.sectionLabelTracking,
                          // Tabular figures so a count ticking 9 -> 10 does not shift
                          // the button beside it.
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            // The v3 spec's clear button paints 36 square. This one is 48,
            // because that is the floor the same design declares for anything
            // a finger has to hit, and `mx_stress_test.dart` enforces it —
            // shrinking the painted box below the target it keeps is the
            // control's call, not this row's, and this control has already
            // made it in favour of the floor (same call as the old 32).
            IconButton(
              onPressed: () => widget.onChanged(''),
              tooltip: widget.clearSemanticLabel,
              icon: Icon(
                Icons.close,
                size: AppIconSize.sm,
                semanticLabel: widget.clearSemanticLabel,
              ),
            ),
          ] else
            // Reserved rather than omitted: an empty field's trailing edge
            // sits where the clear button's would start, so typing the first
            // character does not shift the placeholder that was already there.
            const SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }
}
