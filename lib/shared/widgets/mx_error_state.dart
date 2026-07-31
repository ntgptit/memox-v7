import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';
import 'mx_action_button.dart';

/// Shown when something failed and the user may be able to retry.
///
/// Takes a [message] `String`, never a `Failure`. Two reasons, and both bite
/// later: a shared widget that knows the domain error type drags `core/error`
/// into every UI test, and — more importantly — it would decide how a failure
/// reads, which is the screen's job. The screen picks localized copy for the
/// failure it got; this widget only renders it.
class MxErrorState extends StatelessWidget {
  const MxErrorState({
    required this.title,
    required this.message,
    this.retryLabel,
    this.onRetry,
    super.key,
  }) : assert(
         (retryLabel == null) == (onRetry == null),
         'Retry needs both a label and a callback. Half of the pair is dropped '
         'silently by the build below, which leaves an error the user can read '
         'and cannot act on — the worst of the two states this widget has.',
       );

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
              MxActionButton(
                label: retryLabel!,
                onPressed: onRetry,
                // Primary, not secondary. An error state has exactly one
                // thing to do and nothing to weigh it against — an outlined
                // button there is a quiet control on an otherwise empty screen,
                // which reads as optional. `MxEmptyState`'s action has been
                // primary all along; these two were inconsistent rather than
                // deliberately different.
              ),
            ],
          ],
        ),
      ),
    );
  }
}
