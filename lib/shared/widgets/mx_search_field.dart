import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_durations.dart';
import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_motion_policy.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/foundations/app_stroke.dart';
import '../../core/theme/typography/app_typography.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import 'mx_icon.dart';

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
/// **A custom filled mobile control, not an `InputDecorator` clone** (M100.36
/// 4E). It keeps its own surface model — a well in the page at rest, the paper
/// once focused — and takes its *boundary* from the same system every other
/// control uses: `scheme.outline` at rest, `scheme.primary` with focus, at
/// [AppStroke.input]. Until M100.36 the resting border was the fill's own
/// colour, so the pill had no boundary at all: 1.09:1 against the light page,
/// identified only by its glyph and placeholder (#433 §4.1). A control that is
/// somewhere to type is identified by its edge, which is what WCAG 1.4.11 asks
/// 3:1 of. No shadow: search is flat, and the fill and the edge each carry a
/// different fact.
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
/// **It grows with the text, from a floor of 48** (#433 F2). The pill used to
/// be pinned at `AppSizing.touchTarget` with `expands: true`, which made a
/// documented *floor* into a ceiling: from `textScaler` 2.5 the placeholder
/// was clipped to the box. The floor is a floor now.
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
    final semantic = context.semanticColors;
    final hasQuery = widget.value.isNotEmpty;
    final count = widget.resultCount;
    // **Its own rung, and it is the pill's to own** (M100.36 4P analogue). The
    // form field's hint is `body-lg` because its value is; this pill's value is
    // `body-md` — a search strip under an app bar, not a form — so its
    // placeholder is the same rung, in `onSurfaceVariant`. Stated here rather
    // than read from `inputDecorationTheme.hintStyle`, so the two controls
    // cannot drift apart by one following the other's rung.
    final TextStyle text = context.texts.bodyMedium!;
    final TextStyle hint = text.copyWith(color: colors.onSurfaceVariant);

    return AnimatedContainer(
      // The crossfade between the resting well and the focused surface is
      // decoration on a state change — the state itself is carried by the fill
      // and the border colour, both of which are already correct in the first
      // frame. Reduced motion drops the fade and keeps the state.
      duration: AppMotionPolicy.durationOf(context, AppDurations.fast),
      curve: AppDurations.standard,
      // A floor, as `AppSizing` names it. The row inside grows with the text
      // and the clear button already stands 48 tall, so the pill is 48 at the
      // default scale and taller only when the text needs it.
      constraints: const BoxConstraints(minHeight: AppSizing.touchTarget),
      decoration: BoxDecoration(
        color: _hasFocus ? colors.surface : semantic.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        // `strokeAlignOutside` keeps the stroke out of the layout: a border
        // inside the box would make the pill 51 where the touch target needs
        // its 48, and at 320 wide with `textScaler` 2.0 the chrome has no two
        // pixels to spare.
        border: Border.all(
          color: _hasFocus ? colors.primary : colors.outline,
          width: AppStroke.input,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      // 8 on the trailing side against 12 on the leading one, as the design has
      // it: the glyph needs room off the edge, the clear button brings its own.
      padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
      child: Row(
        // **Centre, not stretch.** The design's `align-items: center` aligns the
        // boxes themselves; stretching them made each child centre its own
        // content by its own rules, and a glyph centred in a 48-tall box does
        // not land where a line of text centred in one does.
        children: <Widget>[
          const MxIcon(Icons.search, size: MxIconSize.sm),
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
                  // draw the form field's 1.5px outline inside it.
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  // `isCollapsed`, not `isDense`: dense keeps some of the
                  // decorator's own vertical padding, and that padding is what
                  // biased the text off the glyph's line. The inset is stated
                  // on the field rather than the pill so the 48-tall clear
                  // button does not add to it: at the default scale the field
                  // is 44 inside a 48 row, and it is the field that grows.
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
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
                    ).copyWith(
                      color: colors.onSurfaceVariant,
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
            // The design's clear button is 32 square. This one is 48, because
            // that is the floor the same design declares for anything a finger
            // has to hit, and `mx_stress_test.dart` enforces it.
            IconButton(
              onPressed: () => widget.onChanged(''),
              tooltip: widget.clearSemanticLabel,
              icon: Icon(
                Icons.close,
                size: AppIconSize.sm,
                semanticLabel: widget.clearSemanticLabel,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
