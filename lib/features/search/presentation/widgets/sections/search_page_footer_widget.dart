import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_text_button.dart';
import '../../states/library_search_state.dart';

/// What sits under the last result: the way to load more, the fact that more is
/// loading, or the fact that loading more failed.
///
/// **A page failing never removes what is already listed** — only this band
/// changes. The results above it are exactly what was found, and an error state
/// over the whole screen would claim otherwise.
/// The stroke `MxActionButton`'s inline spinner uses; the loading-more face
/// borrows the same drawing so the two read as one family.
const double _kSpinnerStroke = 2;

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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        // **Not `MxLoadingState`, for card history's documented reason:** that
        // widget centres a 36dp indicator inside `EdgeInsets.all(xl)`, so the
        // footer would balloon from the button's 48dp to ~88dp the moment
        // Load more is tapped. This is the button's own footprint with the
        // button's spinner in it — centred, because this footer's button is
        // centred (unlike the timeline's leading-aligned tail).
        child: Semantics(
          // Announced, not only drawn — the same `liveRegion` the failure
          // band below carries, and for the same reason: the list stopping
          // partway is the one moment it is deliberately incomplete, and a
          // spinner says nothing at all to a screen reader.
          liveRegion: true,
          child: SizedBox(
            height: AppSpacing.minimumTouchTarget,
            child: Center(
              child: SizedBox.square(
                dimension: AppIconSize.sm,
                child: CircularProgressIndicator(
                  strokeWidth: _kSpinnerStroke,
                  semanticsLabel: context.l10n.librarySearchLoadingMoreLabel,
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (!state.hasMore) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      // Centred where the timeline's tail is leading-aligned: this footer
      // sits under a full-width two-group list, not a left-edged timeline,
      // and its own loading face above keeps the same axis.
      child: Center(
        child: MxTextButton(
          label: context.l10n.librarySearchLoadMoreAction,
          onPressed: onLoadMore,
        ),
      ),
    );
  }

  /// **The app's one in-flow failure grammar** (D24, D25): an `errorContainer`
  /// card, flat, `md` padding, a warning glyph, a title and a message, with
  /// the recovery as a leading-aligned control. Settings, the daily reminder,
  /// the tag rename sheet and card detail's history tail all speak it, and
  /// this band arrived from a branch that had seen none of them — the same
  /// migration card detail's `_PageError` made one stage earlier, for the
  /// same "page N+1 failed, everything read stays above it" moment.
  ///
  /// `Semantics(container: true, liveRegion: true)` wraps the whole band —
  /// announced, not only drawn: the list simply stops otherwise, and a reader
  /// has no way to tell "that is everything" from "the next page failed".
  Widget _failed(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: MxCard(
          color: colors.errorContainer,
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
                      context.l10n.librarySearchLoadMoreErrorTitle,
                      style: context.texts.titleSmall!.inked(
                        context,
                        AppInk.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.l10n.librarySearchLoadMoreErrorMessage,
                      style: context.texts.bodySmall!.inked(
                        context,
                        AppInk.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: MxTextButton(
                        label: context.l10n.retryAction,
                        onPressed: onRetry,
                        accent: colors.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
