import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/navigation/route_names.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_content_shell.dart';
import '../../../../../shared/widgets/mx_error_state.dart';

/// Not-found and read failures on a deck level, told apart (UC-03 E1).
///
/// A deck deleted on another screen produces a [NotFoundFailure], and that is not
/// an error the user caused — it gets its own gentle state with a way back, not a
/// retry button that will fail again forever.
///
/// The root level cannot be missing, so there it is always a read failure — hence
/// [isRootLevel] rather than an inspection of the error alone.
///
/// It lives beside the screen rather than inside it because `deck_list_screen`
/// reached the 400-line guard, and this is the seam that costs nothing: the error
/// state shares no data with the list, only the level it belongs to.
class DeckLevelErrorWidget extends StatelessWidget {
  const DeckLevelErrorWidget({
    required this.error,
    required this.title,
    required this.isRootLevel,
    required this.onRetry,
    super.key,
  });

  final Object error;

  /// The app-bar title, or null inside a deck — where the name was in the read
  /// that just failed.
  final String? title;
  final bool isRootLevel;

  /// Re-reads the level. Supplied by the caller, which owns the `ref`.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isMissing = !isRootLevel && error is NotFoundFailure;

    return MxContentShell(
      title: title,
      body: MxErrorState(
        title: isMissing
            ? context.l10n.deckDetailNotFoundTitle
            : context.l10n.decksLoadErrorTitle,
        // The failure itself never reaches the screen. A Drift message would tell
        // the user nothing they can act on, and can carry a deck name.
        message: isMissing
            ? context.l10n.deckDetailNotFoundMessage
            : context.l10n.decksLoadErrorMessage,
        retryLabel: isMissing
            ? context.l10n.deckBackToDecksAction
            : context.l10n.retryAction,
        onRetry: isMissing ? () => context.goNamed(RouteNames.decks) : onRetry,
      ),
    );
  }
}
