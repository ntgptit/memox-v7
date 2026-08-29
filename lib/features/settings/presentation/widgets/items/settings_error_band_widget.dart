import 'package:flutter/material.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_text_button.dart';
import '../support/settings_labels_widget.dart';
import '../../../../../shared/widgets/mx_feedback_band.dart';

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
    return MxFeedbackBand(
      title: context.l10n.settingsSaveErrorTitle,
      message: context.settingsWriteFailure(failure),
      action: MxTextButton(
        label: context.l10n.retryAction,
        onPressed: onRetry,
        accent: context.colors.onErrorContainer,
      ),
    );
  }
}
