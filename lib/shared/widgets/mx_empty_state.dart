import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import 'mx_action_button.dart';
import 'mx_button_pair.dart';
import '../../core/theme/extensions/app_ink.dart';
import 'mx_icon.dart';

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
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.icon = Icons.check_circle_outline,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'An empty state has an action or it does not. With only a label the '
         'button renders and does nothing; with only a callback it never '
         'renders at all — and either way the build below drops it silently, so '
         'the screen looks deliberately action-free and no test fails.',
       ),
       assert(
         (secondaryActionLabel == null) == (onSecondaryAction == null),
         'Same rule as the primary pair.',
       ),
       assert(
         secondaryActionLabel == null || actionLabel != null,
         'A secondary action needs a primary to be secondary to: alone it '
         'would render as the one action, styled as though it were not.',
       );

  /// Already-localized. The screen owns the copy.
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// A second way forward, under the first and quieter than it.
  ///
  /// For the empty state that genuinely has two next steps — an empty library
  /// offers ready-made content *and* a blank deck (UC-01) — where hiding one
  /// behind the other would decide for the user which kind of start theirs is.
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // `AppInk.accent` is `primary`, and since M100.18 that is the
            // whole story: the dark accent inverted to tone 80, so the brand
            // hue reads as a mark on the page at 11.36:1. This used to reach
            // for a separate text-safe token because the old fill tone managed
            // 3.29:1 there.
            MxIcon(icon, ink: AppInk.accent, size: MxIconSize.lg),
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
                style: context.texts.bodyMedium!.inked(context, AppInk.quiet),
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              // **The pair goes through `MxButtonPair`, which is what makes
              // the two buttons one size.** The forced `Axis.vertical` that
              // used to sit here was a decision about labels that no longer
              // exist — it was added when the CTA read `Browse starter
              // library`, which genuinely wrapped at half a phone. The label
              // is `Starter library` now (M99.81), and keeping the override
              // kept the stack for a reason nobody could see. The responsive
              // default measures the real labels: these row, and a locale
              // that outgrows the line stacks content-width and centred.
              if (secondaryActionLabel != null && onSecondaryAction != null)
                MxButtonPair(
                  primary: MxActionButton(
                    label: actionLabel!,
                    onPressed: onAction,
                  ),
                  secondary: MxActionButton(
                    label: secondaryActionLabel!,
                    variant: MxActionButtonVariant.secondary,
                    onPressed: onSecondaryAction,
                  ),
                )
              else
                MxActionButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
