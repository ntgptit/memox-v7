import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_text_button.dart';
import '../../states/card_history_state.dart';
import '../items/card_history_event_widget.dart';
import '../../../../../shared/widgets/mx_feedback_band.dart';

/// The review timeline (BR-241…BR-244, M4.15 W2 band 3).
///
/// **Grouped by the generation stored on each row, with a text heading**
/// (BR-243, M4.15 V6). A Reset keeps the history but cuts its meaning in two: a
/// `Box 2 → 3` from before a reset and one from after it are not steps of the
/// same progression, and laid out purely by time they look like it. The heading
/// is words rather than a colour band because the grouping has to survive being
/// read without colour.
///
/// **Headings are not sticky, deliberately** (M4.15 V7). The number of groups
/// is the number of resets, which is one for almost every card; a sliver per
/// group would buy scroll behaviour nobody reaches for and cost the whole band
/// its simple layout.
///
/// **Not scrollable itself.** It is a band of the screen's single scroll view,
/// so the reader scrolls one surface rather than fighting a list nested inside
/// a page (M4.15 V4).
///
/// **The band has no card of its own; each event has one.** The heading, the
/// empty face, the initial spinner and all four tails sit on the page at the
/// screen gutter, and the event cards line up with them — so the timeline reads
/// as a run of records rather than as one long box with rows in it. A card that appeared only
/// once there were events would make "this card has no reviews yet" look like a
/// band that failed to render, and would move the tail's left edge the moment
/// the first review landed. The heading stays *outside* it, on the screen's
/// gutter, because it titles the surface rather than sitting in it — the same
/// relationship the schedule panel's heading has to its panel (G1).
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
        Text(
          context.l10n.cardHistoryTitle.toUpperCase(),
          style: context.textStyles.sectionLabel.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.isLoadingInitial)
          // **Not `MxLoadingState`** (V12). That widget centres a 36dp
          // indicator inside `EdgeInsets.all(xl)`, so the spinner would float
          // in the middle of the band — the only face that does not start where
          // the events, the empty face and all four tails start, and it would
          // jump left the moment the page landed.
          _InlineSpinner(semanticsLabel: context.l10n.cardHistoryLoadingLabel)
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
        // painted glyph on the dark ground — the graphic bar, not the text one,
        // and this glyph sits beside two lines of prose rather than carrying a
        // meaning of its own.
        const MxIcon(Icons.history),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.cardHistoryEmptyTitle,
          style: context.texts.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.cardHistoryEmptyMessage,
          style: context.texts.bodySmall!.inked(context, AppInk.quiet),
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
  /// space between two events (M4.15 G5).
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
          // `bodySmall` at w600, not `labelSmall`: it is the only heading
          // *inside* the timeline card, and one rung below the event lines it
          // introduces made it read as a caption on the event above rather than
          // as the start of a group. `withWeight`, because both faces are
          // variable and a bare `fontWeight:` paints w400 while reporting w600.
          style: context.texts.bodySmall!.inked(
            context,
            AppInk.quiet,
            isEmphasized: true,
          ),
        ),
      ),
    );
  }
}

/// The bottom of the timeline: `Load more`, the error band, the completion
/// line, or nothing.
///
/// **All four occupy the same slot** (M4.15 G6), so moving between them never
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
        child: _InlineSpinner(
          semanticsLabel: context.l10n.cardHistoryLoadingMoreLabel,
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
          style: context.texts.bodySmall!.inked(context, AppInk.quiet),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// A spinner in the band's own grammar: glyph-sized, on the band's left edge,
/// in a box exactly one touch target tall.
///
/// **Both faces that spin use it, and that is the point.** `MxLoadingState`
/// centres a 36dp indicator inside `EdgeInsets.all(xl)` — 84dp tall and in the
/// middle of the surface. In the tail that grows the slot from 48 to 84 and
/// shifts the events above, which W3 face 5 forbids; at the top of the band it
/// puts the one face that has nothing above it 40dp in from an edge every other
/// face starts on, and then jumps left when the page lands. Same footprint as
/// `MxActionButton`'s in-button indicator, so the band spins the same way
/// wherever it spins.
class _InlineSpinner extends StatelessWidget {
  const _InlineSpinner({required this.semanticsLabel});

  /// Already-localized, and different per face: "loading the history" and
  /// "loading more" are two different sentences to a screen reader.
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.minimumTouchTarget,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox.square(
          dimension: AppIconSize.sm,
          child: CircularProgressIndicator(
            strokeWidth: _spinnerStroke,
            semanticsLabel: semanticsLabel,
          ),
        ),
      ),
    );
  }
}

/// The failed-page band: everything already read stays above it (UC-19 E4).
///
/// **The app's one in-flow failure grammar** (D24, D25): an `errorContainer`
/// card, flat, `md` padding, a warning glyph, a title and a message, with the
/// recovery as a leading-aligned control. Settings, the daily reminder and the
/// tag rename sheet all speak it, and this screen arrived from a branch that
/// had seen none of them — a user who met that band on any of the three would
/// have found a fourth, unrelated-looking face here.
///
/// **A taller band does not violate G6.** That rule says the tail must not
/// shift the events above it; this is the last element in the column, so it
/// grows downwards into space nothing else occupies.
class _PageError extends StatelessWidget {
  const _PageError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: MxFeedbackBand(
        title: context.l10n.cardHistoryPageErrorTitle,
        message: context.l10n.cardHistoryPageErrorMessage,
        action: MxTextButton(
          label: context.l10n.retryAction,
          onPressed: onRetry,
          accent: context.colors.onErrorContainer,
        ),
      ),
    );
  }
}

/// The stroke of the inline spinner, on either face that spins.
///
/// 2, the same weight `MxActionButton` uses for its in-button indicator — a
/// spinner sized down to a glyph keeps the default 4 only by looking like a
/// ring rather than a spinner.
const double _spinnerStroke = 2;
