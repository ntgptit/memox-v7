import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/typography/app_typography.dart';

/// Lifecycle names whose labels and semantic colours are shared product copy.
enum MxCardStatus { newCard, learning, reviewing, mastered }

/// A non-interactive card lifecycle marker, either a named pill or bare dot.
class MxStatusBadge extends StatelessWidget {
  const MxStatusBadge({
    required this.status,
    this.label,
    this.dotOnly = false,
    super.key,
  });

  static const Key dotKey = ValueKey<String>('mx-status-badge-dot');

  final MxCardStatus status;
  final String? label;
  final bool dotOnly;

  String get _defaultLabel => switch (status) {
    MxCardStatus.newCard => 'New',
    MxCardStatus.learning => 'Learning',
    MxCardStatus.reviewing => 'Reviewing',
    MxCardStatus.mastered => 'Mastered',
  };

  Color _color(BuildContext context) => switch (status) {
    MxCardStatus.newCard => context.semanticColors.statusNew,
    MxCardStatus.learning => context.semanticColors.statusLearning,
    MxCardStatus.reviewing => context.semanticColors.statusReviewing,
    MxCardStatus.mastered => context.semanticColors.statusMastered,
  };

  @override
  Widget build(BuildContext context) {
    final Color color = _color(context);
    final double dotSize = dotOnly ? AppSizing.statusDot : 6;
    final Widget dot = SizedBox(
      key: dotKey,
      width: dotSize,
      height: dotSize,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
    if (dotOnly) return ExcludeSemantics(child: dot);

    return Semantics(
      label: label ?? _defaultLabel,
      child: ExcludeSemantics(
        child: Container(
          height: 22,
          padding: const EdgeInsets.only(left: 6, right: AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              dot,
              const SizedBox(width: AppSpacing.xs),
              Text(
                label ?? _defaultLabel,
                style: AppTypography.withWeight(
                  context.texts.labelSmall!.copyWith(color: color, height: 1),
                  FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
