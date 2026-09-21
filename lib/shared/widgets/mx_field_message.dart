import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_spacing.dart';

/// The validation message beneath a field-like surface.
///
/// This is a surface, not a control: callers own validation and placement;
/// this widget owns the shared glyph, tone, internal geometry and wrapping.
enum MxFieldMessageTone { error, warning }

class MxFieldMessage extends StatelessWidget {
  const MxFieldMessage({
    required this.message,
    this.tone = MxFieldMessageTone.error,
    super.key,
  });

  /// Already-localized validation text.
  final String message;
  final MxFieldMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final isWarning = tone == MxFieldMessageTone.warning;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xs,
        left: AppSpacing.xs,
        right: AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.error_outline,
            size: AppIconSize.sm,
            color: isWarning
                ? context.semanticColors.warning
                : context.colors.error,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: context.texts.labelMedium!.inked(
                context,
                isWarning ? AppInk.warning : AppInk.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
