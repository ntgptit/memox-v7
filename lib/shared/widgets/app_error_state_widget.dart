import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';
import 'app_button_widget.dart';

/// Shown when something failed and the user may be able to retry.
///
/// Takes a [message] `String`, never a `Failure`. Two reasons, and both bite
/// later: a shared widget that knows the domain error type drags `core/error`
/// into every UI test, and — more importantly — it would decide how a failure
/// reads, which is the screen's job. The screen picks localized copy for the
/// failure it got; this widget only renders it.
class AppErrorStateWidget extends StatelessWidget {
  const AppErrorStateWidget({
    required this.title,
    required this.message,
    this.retryLabel,
    this.onRetry,
    super.key,
  });

  /// Already-localized, and already free of technical detail.
  final String title;
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: AppIconSize.lg,
              color: context.semanticColors.danger,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.texts.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (retryLabel != null && onRetry != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              AppButtonWidget(
                label: retryLabel!,
                onPressed: onRetry,
                variant: AppButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
