import 'package:flutter/material.dart';

import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_loading_state.dart';
import '../../../../../shared/widgets/mx_text_button.dart';
import '../../states/card_history_state.dart';
import '../items/card_history_event_widget.dart';

/// The review timeline (BR-241…BR-244, M4.14 W2 band 3).
///
/// **Grouped by the generation stored on each row, with a text heading**
/// (BR-243, M4.14 V6). A Reset keeps the history but cuts its meaning in two: a
/// `Box 2 → 3` from before a reset and one from after it are not steps of the
/// same progression, and laid out purely by time they look like it. The heading
/// is words rather than a colour band because the grouping has to survive being
/// read without colour.
///
/// **Headings are not sticky, deliberately** (M4.14 V7). The number of groups
/// is the number of resets, which is one for almost every card; a sliver per
/// group would buy scroll behaviour nobody reaches for and cost the whole band
/// its simple layout.
///
/// **Not scrollable itself.** It is a band of the screen's single scroll view,
/// so the reader scrolls one surface rather than fighting a list nested inside
/// a page (M4.14 V4).
class CardHistorySectionWidget extends StatelessWidget {
  const CardHistorySectionWidget({
    required this.state,
    required this.onLoadMore,
    super.key,
  });

  final CardHistoryState state;

  /// Fetches the page after what is shown — the same command behind both
  /// `Load more` and `Try again`, because they are the same operation under two
  /// labels (UC-19 E4).
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(context.l10n.cardHistoryTitle, style: context.texts.titleSmall),
        const SizedBox(height: AppSpacing.md),
        if (state.isLoadingInitial)
          MxLoadingState(semanticsLabel: context.l10n.cardHistoryLoadingLabel)
        else if (state.isEmpty)
          const _EmptyHistory()
        else
          ..._groups(context),
        _Tail(state: state, onLoadMore: onLoadMore),
      ],
    );
  }

  /// The events, split where the stored generation changes.
  ///
  /// A single pass over an already newest-first list: the rows arrive ordered,
  /// so a group boundary is simply the point where the value differs from the
  /// row above it. Sorting or bucketing into a map would reorder events inside
  /// a group, which BR-241 fixes.
  List<Widget> _groups(BuildContext context) {
    final widgets = <Widget>[];
    int? currentGeneration;

    for (var index = 0; index < state.events.length; index++) {
      final event = state.events[index];
      if (event.schedulerGeneration != currentGeneration) {
        currentGeneration = event.schedulerGeneration;
        widgets.add(
          _GenerationHeading(
            generation: currentGeneration,
            // The newest event is on the generation the card is on now, so the
            // first heading names the current cycle rather than a number the
            // user has no way to interpret.
            isCurrent: index == 0,
            isFirst: widgets.isEmpty,
          ),
        );
      }
      widgets.add(
        CardHistoryEventWidget(
          event: event,
          isFirst: _isFirstOfGroup(index),
          isLast: _isLastOfGroup(index),
          key: ValueKey<String>(event.id),
        ),
      );
    }

    return widgets;
  }

  /// Whether the connector should start here — at the top of the list, or under
  /// a heading that has just broken the run.
  bool _isFirstOfGroup(int index) {
    final events = state.events;
    if (index == 0) return true;

    return events[index - 1].schedulerGeneration !=
        events[index].schedulerGeneration;
  }

  /// Whether the connector should stop here — at the end of the list, or where
  /// the next event belongs to a different generation and a heading comes
  /// between.
  bool _isLastOfGroup(int index) {
    final events = state.events;
    if (index == events.length - 1) return true;

    return events[index + 1].schedulerGeneration !=
        events[index].schedulerGeneration;
  }
}

/// A card with no reviews yet — valid, and never an error (BR-244).
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // A glyph, as W3 face 2 asks — but not `MxEmptyState`, which is a
        // centred, scrollable full-screen face and would fight a band that
        // lives inside the screen's own scroll view.
        //
        // `onSurfaceVariant`, not `primary`: the accent measures 3.29:1 as a
        // painted glyph on the dark ground, the same number `_FlagRow` cites.
        Icon(
          Icons.history,
          size: AppIconSize.md,
          color: context.colors.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.cardHistoryEmptyTitle,
          style: context.texts.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.cardHistoryEmptyMessage,
          style: context.texts.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The heading above one generation's events (BR-243).
class _GenerationHeading extends StatelessWidget {
  const _GenerationHeading({
    required this.generation,
    required this.isCurrent,
    required this.isFirst,
  });

  final int generation;
  final bool isCurrent;

  /// Whether it opens the band — the first heading needs no gap above it, the
  /// later ones need a clear one so a group boundary reads as wider than the
  /// space between two events (M4.14 G5).
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 0 : AppSpacing.sm,
        bottom: AppSpacing.md,
      ),
      child: Semantics(
        header: true,
        child: Text(
          isCurrent
              ? context.l10n.cardHistoryCurrentGenerationLabel
              : context.l10n.cardHistoryGenerationLabel(generation),
          style: context.texts.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// The bottom of the timeline: `Load more`, the error band, the completion
/// line, or nothing.
///
/// **All four occupy the same slot** (M4.14 G6), so moving between them never
/// shifts the event above.
class _Tail extends StatelessWidget {
  const _Tail({required this.state, required this.onLoadMore});

  final CardHistoryState state;

  /// Fetches the page after what is shown — the same command behind both
  /// `Load more` and `Try again`, because they are the same operation under two
  /// labels (UC-19 E4).
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.hasPageError) {
      return _PageError(onRetry: onLoadMore);
    }
    if (state.isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        // **Not `MxLoadingState`, and that is the whole point of this branch.**
        // That widget centres a 36dp indicator inside `EdgeInsets.all(xl)`, so
        // the tail would grow from 48 to 84 and jump from the events' left edge
        // to the middle of the screen — exactly the shift W3 face 5 forbids.
        // This is the button's own footprint with the button's spinner in it,
        // the shape `MxActionButton` already uses inline.
        child: SizedBox(
          height: AppSpacing.minimumTouchTarget,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox.square(
              dimension: AppIconSize.sm,
              child: CircularProgressIndicator(
                strokeWidth: _spinnerStroke,
                semanticsLabel: context.l10n.cardHistoryLoadingMoreLabel,
              ),
            ),
          ),
        ),
      );
    }
    if (state.hasMore) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: MxTextButton(
          label: context.l10n.cardHistoryLoadMoreAction,
          onPressed: onLoadMore,
        ),
      );
    }
    if (state.isComplete) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        // **Countless, deliberately.** This line used to say "N reviews in
        // total", which BR-243 forbids — and it was already wrong: `Reviews` in
        // the band above counts `scheduled` turns only (BR-20), while the
        // history holds `learning` and `relearning` rows across every
        // generation, so the two numbers disagreed on the same screen.
        child: Text(
          context.l10n.cardHistoryAllShownLabel,
          style: context.texts.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// The failed-page band: one line and a retry, with everything already read
/// still above it (UC-19 E4).
class _PageError extends StatelessWidget {
  const _PageError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              context.l10n.cardHistoryPageErrorMessage,
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.error,
              ),
            ),
            MxTextButton(
              label: context.l10n.cardHistoryRetryAction,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// The stroke of the inline load-more spinner.
///
/// 2, the same weight `MxActionButton` uses for its in-button indicator — a
/// spinner sized down to a glyph keeps the default 4 only by looking like a
/// ring rather than a spinner.
const double _spinnerStroke = 2;
