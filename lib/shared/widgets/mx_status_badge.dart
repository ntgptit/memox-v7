import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_semantic_colors.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';

/// The handoff's card lifecycle: new ▸ learning ▸ reviewing ▸ mastered.
enum MxStatusTone { isNew, learning, reviewing, mastered }

/// Pill (dot + label) or the bare dot.
enum MxStatusBadgeForm { pill, dot }

/// Handoff StatusBadge (section E). The dot carries the status colour; the
/// label reads in `onSurfaceVariant` (D24). Non-interactive.
class MxStatusBadge extends StatelessWidget {
  const MxStatusBadge({
    required this.tone,
    required this.label,
    this.form = MxStatusBadgeForm.pill,
    super.key,
  });

  final MxStatusTone tone;

  /// Already-localized. Painted in the pill; the dot's accessible name.
  final String label;
  final MxStatusBadgeForm form;

  Color _dotColor(AppSemanticColors semantic) => switch (tone) {
    MxStatusTone.isNew => semantic.statusNew,
    MxStatusTone.learning => semantic.statusLearning,
    MxStatusTone.reviewing => semantic.statusReviewing,
    MxStatusTone.mastered => semantic.statusMastered,
  };

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final Widget dot = SizedBox.square(
      dimension: AppSizing.statusDot,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _dotColor(semantic),
          shape: BoxShape.circle,
        ),
      ),
    );
    if (form == MxStatusBadgeForm.dot) {
      return Semantics(label: label, child: dot);
    }

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: semantic.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.xs,
            children: <Widget>[
              dot,
              // One line, cut rather than pushed: a long state word at 320dp and
              // 2.0x overflowed the pill by up to 96px before this (M100.91).
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelMedium!.inked(
                    context,
                    AppInk.quiet,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
