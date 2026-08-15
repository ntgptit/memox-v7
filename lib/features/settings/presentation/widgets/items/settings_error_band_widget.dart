import 'package:flutter/material.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_text_button.dart';
import '../support/settings_labels_widget.dart';

/// The in-section error band (wireframe W3 state 6, S8).
///
/// **In `items/` rather than `sections/`** (AD-15): three groups render it, so
/// it is a repeated part rather than a band one screen composes.
///
/// **Inside the group that failed, not at the bottom of the screen.** Three
/// groups are three transactions (BR-216), and an error at the foot of the page
/// would answer "something failed" without answering which — the question the
/// user needs to act.
///
/// Icon **and** words: colour alone says nothing to a screen reader and nothing
/// to roughly one man in twelve. The copy comes from the failure *type*; the
/// failure's own diagnostic message is never rendered (BR-216).
///
/// **A live region, because nothing else announces it.** It appears while focus
/// is still on the control the user just touched, which does not change — so
/// without this a screen-reader user is told nothing at all.
class SettingsErrorBandWidget extends StatelessWidget {
  const SettingsErrorBandWidget({
    required this.failure,
    required this.onRetry,
    super.key,
  });

  final Failure failure;

  /// `null` while a retry is already in flight, which disables the button
  /// rather than hiding it — a control that disappears under the finger is a
  /// second surprise on top of the failure.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      container: true,
      liveRegion: true,
      child: MxCard(
        color: colors.errorContainer,
        // Flat: the band sits inside a card that already carries the app's one
        // elevation, and a shadow stacked on a shadow is a rendering fault
        // rather than depth (`MxCard`).
        elevation: AppElevation.none,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: AppIconSize.mdCompact,
              color: colors.onErrorContainer,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    context.l10n.settingsSaveErrorTitle,
                    style: context.texts.titleSmall?.copyWith(
                      color: colors.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.settingsWriteFailure(failure),
                    style: context.texts.bodySmall?.copyWith(
                      color: colors.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    // **`onErrorContainer`, because this button sits on
                    // `errorContainer`.** `MxTextButton` resolves to
                    // `primaryAccent`, which is right on a page and measures
                    // **3.72:1** here in dark — under the 4.5 its 14px w600
                    // label needs. The band's own text already uses
                    // `onErrorContainer` and reaches 8.33:1; the button joins
                    // it rather than inventing a third ink.
                    child: TextButtonTheme(
                      data: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: context.colors.onErrorContainer,
                        ),
                      ),
                      child: MxTextButton(
                        label: context.l10n.retryAction,
                        onPressed: onRetry,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
