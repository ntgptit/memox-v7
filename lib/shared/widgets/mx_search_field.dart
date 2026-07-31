import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
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

  @override
  void didUpdateWidget(MxSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only when the value genuinely differs — assigning `text` moves the caret
    // to the end, so doing it on every rebuild would fight the user mid-word.
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = widget.value.isNotEmpty;
    final count = widget.resultCount;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.semanticColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.search,
              size: AppIconSize.sm,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                textInputAction: TextInputAction.search,
                style: context.texts.bodyMedium,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  // The pill *is* the decoration. Left to the theme this would
                  // draw the form field's 1.5px outline inside it.
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            // The count and the clear button appear together, and only once
            // something has been typed — an empty field with a clear button on
            // it offers to undo nothing.
            if (hasQuery) ...<Widget>[
              if (count != null) ...<Widget>[
                Text(
                  '$count',
                  style: context.texts.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
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
              const SizedBox(width: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
