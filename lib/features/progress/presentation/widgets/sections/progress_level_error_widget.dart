import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_content_shell.dart';
import '../../../../../shared/widgets/mx_empty_state.dart';
import '../../../../../shared/widgets/mx_error_state.dart';
import '../support/progress_labels_widget.dart';

/// The two ways a level can fail to render, told apart.
///
/// **A deleted deck is not an error.** Nothing went wrong: the deck the link
/// names is gone, and re-reading will find it gone again — so Retry would offer
/// an action guaranteed to fail. That branch gets an empty state and the one
/// thing that helps, the way back to the level that still exists.
///
/// Everything else is a read failure, which a retry can genuinely fix, so it
/// gets `MxErrorState` and a retry.
///
/// The failure object never reaches the screen: `progressErrorCopyOf` maps the
/// *type* to ARB copy, and `Failure.message` is an unlocalized diagnostic
/// written for a log.
class ProgressLevelErrorWidget extends StatelessWidget {
  const ProgressLevelErrorWidget({
    required this.error,
    required this.title,
    required this.onRetry,
    required this.onLeave,
    super.key,
  });

  final Object error;

  /// The app-bar title to keep while the level cannot render. Null where there
  /// honestly is none — a deck's title is its name, and the name is in the data
  /// that failed to arrive.
  final String? title;

  final VoidCallback onRetry;

  /// Where a level whose deck is gone sends the user: the library level of
  /// Progress, which is where the deck used to be listed.
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final copy = progressErrorCopyOf(context, error);

    return MxContentShell(
      title: title,
      body: copy.isDeckMissing
          ? MxEmptyState(
              icon: Icons.folder_off_outlined,
              title: copy.title,
              message: copy.message,
              actionLabel: context.l10n.progressDeckMissingBackAction,
              onAction: onLeave,
            )
          : MxErrorState(
              title: copy.title,
              message: copy.message,
              retryLabel: context.l10n.progressErrorRetryAction,
              onRetry: onRetry,
            ),
    );
  }
}
