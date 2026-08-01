import 'package:flutter/material.dart';

import '../../core/theme/app_durations.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_motion_policy.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_context_extension.dart';

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
/// **Focus changes the fill and the border, never a size.** The design's
/// `.mx-search` carries a 1px *transparent* border at rest precisely so that
/// gaining one on focus moves nothing beside it — the same rule the form input
/// follows, where focus shifts the border's hue and not its width. The pill also
/// lifts from `surfaceMuted` to `surface`: a field being typed into stops being
/// a well in the page and becomes a surface of its own.
class MxSearchField extends StatefulWidget {
  const MxSearchField({
    required this.value,
    required this.onChanged,
    required this.hintText,
    this.resultCount,
    this.clearSemanticLabel,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;

  /// Already-localized, and it should name the **scope**: on a nested level the
  /// user needs to know whether they are searching this deck or everything.
  final String hintText;

  /// Shown while there is a query. Omit when the screen does not know yet.
  final int? resultCount;

  /// Already-localized label for the clear button.
  final String? clearSemanticLabel;

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

    return AnimatedContainer(
      // The crossfade between the resting well and the focused surface is
      // decoration on a state change — the state itself is carried by the fill
      // and the border colour, both of which are already correct in the first
      // frame. Reduced motion drops the fade and keeps the state.
      duration: AppMotionPolicy.durationOf(context, AppDurations.fast),
      curve: AppDurations.standard,
      decoration: BoxDecoration(
        color: _hasFocus ? colors.surface : semantic.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        // **Always drawn, and the same colour as the fill at rest.** The design
        // uses a transparent border here so that gaining one on focus moves
        // nothing beside it; a fully transparent colour is not a palette token
        // and the audit blocks it — correctly, since "alpha zero" is how an
        // unowned colour hides. Painting the fill's own colour is invisible in
        // the same way and is a token.
        //
        // `strokeAlignOutside` keeps the stroke out of the layout: a border
        // inside the box would make the pill 50 where the touch target needs
        // its 48, and at 320 wide with `textScaler` 2.0 the chrome has no two
        // pixels to spare.
        border: Border.all(
          color: _hasFocus ? semantic.focusRing : semantic.surfaceMuted,
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
          Icon(
            Icons.search,
            size: AppIconSize.sm,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            // The 48 lives on the box, not on the decorator. Asking
            // `InputDecoration` for a minimum height grew the box and left the
            // text against its ceiling — which is exactly the "icon and hint on
            // different lines" this was reported as. Letting the field expand
            // into the fixed-height box keeps the tap target at 48, and the
            // tiny upward nudge keeps the hint from sitting 2px lower than the
            // search icon.
            child: SizedBox(
              height: AppSpacing.minimumTouchTarget,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                textInputAction: TextInputAction.search,
                style: context.texts.bodyMedium,
                expands: true,
                maxLines: null,
                // Nudge the editable up a hair so the hint's bottom edge lines
                // up with the search icon instead of sitting 2px lower.
                textAlignVertical: const TextAlignVertical(y: -0.1),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  // The pill *is* the decoration. Left to the theme this would
                  // draw the form field's 1.5px outline inside it.
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  // `isCollapsed`, not `isDense`: dense keeps some of the
                  // decorator's own vertical padding, and that padding is what
                  // biased the text off the glyph's line.
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
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
                style: context.texts.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
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
