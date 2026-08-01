import 'package:flutter/material.dart';

import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';

/// A short banner explaining why an action is not available in this build.
///
/// Used for the card handoff to M4.11. It is a statement, not a control: an
/// enabled-looking button that does nothing is worse than no button, and hiding
/// the fact entirely would leave an `unset` deck looking as though it could only
/// ever hold decks — which contradicts BR-61.
class DeckNoticeWidget extends StatelessWidget {
  const DeckNoticeWidget({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: AppIconSize.sm,
            color: context.semanticColors.info,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
