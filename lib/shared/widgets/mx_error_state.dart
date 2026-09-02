import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import 'mx_action_button.dart';
import '../../core/theme/extensions/app_ink.dart';
import 'mx_icon.dart';

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
    this.isRetrying = false,
    super.key,
  }) : assert(
         !isRetrying || onRetry != null,
         'isRetrying without a retry is a spinner on a button that is not '
         'there. Same failure as the pair below: a state the widget cannot '
         'render, accepted silently.',
       ),
       assert(
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

  /// Whether the retry the user asked for is still running.
  ///
  /// **Without this the control was a lie.** `ref.invalidate` produces a
  /// *refresh*, and `MxAsyncView` keeps the previous value through a refresh for
  /// every screen — which on a failure means the same error face is painted
  /// again, unchanged. Six frames were measured after a tap and not one pixel
  /// moved: the person pressed a button and got no evidence the app had noticed,
  /// on a screen whose read is a full scan.
  ///
  /// `MxActionButton` already knows how to say this, and the default shape is
  /// the right one here: the label keeps its **layout slot** at `opacity 0` with
  /// the spinner centred over it, so the button's rect does not move by a pixel
  /// under the finger that just pressed it. `shouldKeepLabelWhileLoading` is the
  /// other trade — label and spinner side by side — and it widens the button by
  /// `AppIconSize.sm + AppSpacing.sm`, which is exactly the jump this is
  /// avoiding. The name survives for a screen reader through the button's own
  /// `alwaysIncludeSemantics`. All that was missing was passing the flag
  /// through.
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const MxIcon(
              Icons.error_outline,
              ink: AppInk.danger,
              size: MxIconSize.lg,
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
                isLoading: isRetrying,
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
