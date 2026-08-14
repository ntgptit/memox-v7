import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_loading_state.dart';
import '../../../../../shared/widgets/mx_text_button.dart';
import '../../states/library_search_state.dart';

/// What sits under the last result: the way to load more, the fact that more is
/// loading, or the fact that loading more failed.
///
/// **A page failing never removes what is already listed** — only this band
/// changes. The results above it are exactly what was found, and an error state
/// over the whole screen would claim otherwise.
class SearchPageFooterWidget extends StatelessWidget {
  const SearchPageFooterWidget({
    required this.state,
    required this.onLoadMore,
    required this.onRetry,
    super.key,
  });

  final LibrarySearchState state;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.pageError != null) return _failed(context);
    if (state.isLoadingMore) {
      return Semantics(
        // Announced, not only drawn — the same `liveRegion` the failure band
        // below carries, and for the same reason: the list stopping partway is
        // the one moment it is deliberately incomplete, and a spinner says
        // nothing at all to a screen reader.
        liveRegion: true,
        // The shared loading state, so the spinner's colour comes from the
        // theme that was measured for contrast rather than from this call site.
        child: MxLoadingState(
          semanticsLabel: context.l10n.librarySearchLoadingMoreLabel,
        ),
      );
    }
    if (!state.hasMore) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: MxTextButton(
          label: context.l10n.librarySearchLoadMoreAction,
          onPressed: onLoadMore,
        ),
      ),
    );
  }

  Widget _failed(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Column(
      children: <Widget>[
        Semantics(
          // Announced, not only drawn: the list simply stops otherwise, and a
          // reader has no way to tell "that is everything" from "the next page
          // failed".
          liveRegion: true,
          child: Text(
            context.l10n.librarySearchLoadMoreErrorMessage,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.error,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        MxTextButton(label: context.l10n.retryAction, onPressed: onRetry),
      ],
    ),
  );
}
