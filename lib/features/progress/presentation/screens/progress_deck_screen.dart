import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../domain/models/deck_activity_model.dart';
import '../../domain/models/deck_activity_order_model.dart';
import '../../domain/models/deck_activity_snapshot_model.dart';
import '../../domain/models/progress_range_model.dart';
import '../controllers/deck_activity_controller.dart';
import '../controllers/progress_range_controller.dart';
import '../widgets/sections/progress_deck_list_widget.dart';
import '../widgets/sections/progress_level_error_widget.dart';
import '../widgets/sections/progress_range_selector_widget.dart';
import '../widgets/sections/progress_summary_widget.dart';

/// The range command, bound to a `ref`.
///
/// A free function rather than a closure written inline in `build()`. `ref.read`
/// is the right call — choosing a window is a command, and a `watch` inside a
/// callback would subscribe the widget to a value it is about to set — but
/// written inline it sits lexically inside `build`, where neither a reader nor
/// `memox.state_management.no_ref_read_in_build` can tell a deliberate command
/// from a missed subscription.
ValueChanged<ProgressRange> _selectRange(WidgetRef ref) =>
    (ProgressRange value) =>
        ref.read(progressRangeChoiceProvider.notifier).select(value);

/// One level of Progress by Deck (UC-12).
///
/// **The same screen at every depth**, for the reason `DeckListScreen` states:
/// [deckId] null is the library — every root deck and the totals across them —
/// and any other id is that deck's own level. Drilling in does not change what
/// the user is looking at, only which part of the tree it is about, so it does
/// not get a different screen and cannot drift from the level above it.
///
/// What legitimately differs by level comes entirely from the snapshot: the
/// title, and which empty state applies when there is nothing to list.
class ProgressDeckScreen extends StatelessWidget {
  const ProgressDeckScreen({this.deckId, super.key});

  /// Null at the library level.
  final String? deckId;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) =>
          MxAsyncView<DeckActivitySnapshot>(
            value: ref.watch(deckActivityLevelProvider(deckId)),
            loadingLabel: context.l10n.progressLoadingLabel,
            // The shell is inside each branch rather than around them, because
            // the title is only knowable in some of them — see
            // [_titleBeforeData].
            loadingFrame: (Widget loading) =>
                MxContentShell(title: _titleBeforeData(context), body: loading),
            data: (DeckActivitySnapshot snapshot) => _ProgressLevel(
              snapshot: snapshot,
              range: ref.watch(progressRangeChoiceProvider),
              onRangeChanged: _selectRange(ref),
            ),
            error: (Object error, StackTrace stackTrace) =>
                ProgressLevelErrorWidget(
                  error: error,
                  title: _titleBeforeData(context),
                  // `invalidate`, not `refresh`: the retry wants a read from
                  // scratch and nothing here needs the new value as a return.
                  onRetry: () =>
                      ref.invalidate(deckActivityLevelProvider(deckId)),
                  onLeave: () => context.goNamed(RouteNames.progress),
                ),
          ),
    );
  }

  /// The app-bar title for a level whose data has not arrived.
  ///
  /// **The app's own word at every level, including inside a deck.** A deck's
  /// title is its name and the name is in the data that has not arrived, so the
  /// first version returned null there — and `MxContentShell` builds no `AppBar`
  /// at all for a null title, which took the back button with it. That is
  /// survivable on first entry and not survivable on a *reload*: crossing local
  /// midnight and resuming from the background both re-open the read, so a level
  /// the user was already reading would lose its chrome and its way back for as
  /// long as the query ran. Showing the section's name is honest — it is where
  /// the user is — and it never shows the previous deck's name, which was the
  /// thing worth avoiding.
  String _titleBeforeData(BuildContext context) => context.l10n.progressTitle;
}

/// A level that loaded: its chrome, and whatever this level actually shows.
class _ProgressLevel extends StatelessWidget {
  const _ProgressLevel({
    required this.snapshot,
    required this.range,
    required this.onRangeChanged,
  });

  final DeckActivitySnapshot snapshot;
  final ProgressRange range;
  final ValueChanged<ProgressRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return MxContentShell(
      // The level names itself: the app's own word at the top, the deck below.
      title: snapshot.scopeName ?? context.l10n.progressTitle,
      // The shell's own padding is dropped: the body is one scroll view and owns
      // its gutters, so nothing here has a height budget that growing chrome
      // could overflow.
      padding: EdgeInsets.zero,
      // **Pinned, not scrolled.** BR-187 puts fifty decks on this list; two
      // screens down, a selector that scrolled away would leave nothing on
      // screen saying whether the figures are the week or the month. The shell's
      // subheader slot exists for exactly that, and it takes the screen gutter
      // from the shell rather than re-deriving it.
      subheader: _hasNothingToMeasure
          ? null
          : ProgressRangeSelectorWidget(
              range: range,
              onRangeChanged: onRangeChanged,
            ),
      body: _hasNothingToMeasure ? _emptyLevel(context) : _level(context),
    );
  }

  /// The top level with no decks at all.
  ///
  /// **The selector and the panel are not rendered here**, unlike every other
  /// state: with no decks there is no window in which anything could have
  /// happened, so a control switching between two empty answers and a panel of
  /// four zeroes would be three ways of saying the same nothing. A deck level
  /// with no sub-decks is the opposite case — that deck has real figures of its
  /// own — so it keeps both.
  bool get _hasNothingToMeasure =>
      snapshot.isTopLevel && snapshot.decks.isEmpty;

  Widget _level(BuildContext context) {
    // The screen gutter, which is 16 and 12 below the compact breakpoint. Read
    // from the shell's own helper rather than written as `AppSpacing.lg`: the
    // rule belongs to `MxContentShell`, and re-deriving it here is how this
    // screen ends up inset differently from every other one at 320dp — where
    // the 8px it costs is exactly the width the metric cells are short of.
    final gutter = mxScreenGutter(context);

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.md,
              gutter,
              // `xl` below the panel, not `lg`: this is the gap between two
              // *sections* — the total and the decks that make it up — and a
              // section break using the same number as the gap between two
              // rows would make the panel read as the first row of the list.
              AppSpacing.xl,
            ),
            child: ProgressSummaryWidget(snapshot: snapshot, range: range),
          ),
        ),
        if (snapshot.decks.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _emptyLevel(context))
        else
          ProgressDeckListWidget(
            // Ordered here rather than in the repository, because the order
            // depends on which window is selected (BR-187) and the window is a
            // view choice that must not re-open the read.
            decks: sortDeckActivity(snapshot.decks, range: range),
            range: range,
            gutter: gutter,
            // `pushNamed`, not `goNamed`, and that is what makes a deep tree
            // navigable. Every level is the same route with a different id,
            // so `go` would *replace* the current location and Back from
            // level 5 would land on the library rather than on level 4.
            // Pushing stacks them, so Back walks the tree the way the user
            // walked it, and the deep link still resolves because go_router
            // synthesises the same parent from the route hierarchy. The deck
            // list drills the same way for the same reason.
            onOpenDeck: (DeckActivity activity) => context.pushNamed(
              RouteNames.progressDeck,
              pathParameters: <String, String>{
                RoutePathParams.deckId: activity.deckId,
              },
            ),
          ),
      ],
    );
  }

  /// Nothing to list, which means two different things at two levels.
  ///
  /// At the top there are no decks at all — nothing has been measured because
  /// there is nothing to measure. Inside a deck it means the deck holds cards
  /// rather than sub-decks, so its own totals above *are* the whole story and
  /// there is nothing further to drill into. Neither is a failure and neither
  /// offers an action: the next step in both cases lives on the Library tab, and
  /// a button that switched tabs from here would read as a detour.
  Widget _emptyLevel(BuildContext context) => MxEmptyState(
    icon: Icons.folder_outlined,
    title: snapshot.isTopLevel
        ? context.l10n.progressEmptyDecksTitle
        : context.l10n.progressEmptySubDecksTitle,
    message: snapshot.isTopLevel
        ? context.l10n.progressEmptyDecksMessage
        : context.l10n.progressEmptySubDecksMessage,
  );
}
