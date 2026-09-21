import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_spacing.dart';

/// A read-only metadata tag; interactive tag editing uses a control instead.
class MxTagChip extends StatelessWidget {
  const MxTagChip({required this.label, this.dense = false, super.key});

  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 140),
    child: Container(
      height: dense ? 18 : 22,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.texts.labelSmall!
            .inked(context, AppInk.quiet)
            .copyWith(height: 1),
      ),
    ),
  );
}
