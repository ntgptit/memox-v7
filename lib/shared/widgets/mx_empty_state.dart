import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';
import 'mx_action_button.dart';

/// Shown when there is nothing to display and that is fine.
///
/// Deliberately distinct from [MxErrorState]: "you have finished
/// everything due today" is good news, and rendering it in error styling tells
/// the user something is broken when nothing is (BR-29).
class MxEmptyState extends StatelessWidget {
  const MxEmptyState({
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.check_circle_outline,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'An empty state has an action or it does not. With only a label the '
         'button renders and does nothing; with only a callback it never '
         'renders at all — and either way the build below drops it silently, so '
         'the screen looks deliberately action-free and no test fails.',
       );

  /// Already-localized. The screen owns the copy.
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: AppIconSize.lg, color: context.colors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.texts.titleMedium,
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.texts.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              MxActionButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
