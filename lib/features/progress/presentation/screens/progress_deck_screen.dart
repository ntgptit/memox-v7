import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context_extension.dart';
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
import '../widgets/sections/progress_level_header_widget.dart';
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

/// One level of Progress by Deck (UC-13).
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
  const ProgressDeckScreen({this.deckId, this.header, super.key});

  /// Null at the library level.
  final String? deckId;

  /// Rendered above the range selector's panel, at the library level only.
  ///
  /// **This is how the overview and the deck level became one screen.** They
  /// arrived as two features, each claiming `/progress`, and the owner settled
  /// it as one: streak, today and the seven-day chart on top, then the range,
  /// the totals and the deck rows. Passing it in rather than importing the
  /// overview here keeps the direction right — this screen still knows nothing
  /// about the overview, and `ProgressScreen` is the only place the two meet.
  ///
  /// Null inside a deck, and that is not an omission: the three sections
  /// measure the whole library, so repeating them under one deck would answer a
  /// question nobody asked at that level.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        // Read once and held: the error face needs the same `AsyncValue` the
        // view is rendering, to say whether the retry it started is still in
        // flight. Watching twice would be two reads of one fact.
        final AsyncValue<DeckActivitySnapshot> level = ref.watch(
          deckActivityLevelProvider(deckId),
        );

        return MxAsyncView<DeckActivitySnapshot>(
          value: level,
          loadingLabel: context.l10n.progressLoadingLabel,
          // Same reason the overview opts in, and the merge is what made it
          // necessary here too: this level's dependency is
          // `progressNowProvider` — the instant its windows are measured
          // against — which moves on every app resume and at local midnight
          // without the user's question changing. `/progress` now stacks two
          // `MxAsyncView`s, so opting only the overview in left the deck list
          // flashing a spinner under a header that held, which UC-12's UI
          // states and P8 forbid for exactly the same reason.
          shouldSkipLoadingOnReload: true,
          // The shell is inside each branch rather than around them, because
          // the title is only knowable in some of them — see
          // [_titleBeforeData].
          // The band survives the first read as well as a reload. Reaching
          // this frame means the overview has already answered — `/progress`
          // builds this screen only once it has — so a bare spinner here
          // hides three sections that are on hand, which is the same thing
          // P8 forbids on a reload.
          loadingFrame: (Widget loading) => MxContentShell(
            title: _titleBeforeData(context),
            body: ProgressHeaderedBody(header: header, body: loading),
          ),
          data: (DeckActivitySnapshot snapshot) => _ProgressLevel(
            snapshot: snapshot,
            range: ref.watch(progressRangeChoiceProvider),
            onRangeChanged: _selectRange(ref),
            header: header,
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
                header: header,
                isRetrying: level.isRefreshing,
              ),
        );
      },
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
    this.header,
  });

  final DeckActivitySnapshot snapshot;
  final ProgressRange range;
  final ValueChanged<ProgressRange> onRangeChanged;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return MxContentShell(
      // The level names itself: the app's own word at the top, the deck below.
      title: snapshot.scopeName ?? context.l10n.progressTitle,
      // The shell's own padding is dropped: the body is one scroll view and owns
      // its gutters, so nothing here has a height budget that growing chrome
      // could overflow.
      padding: EdgeInsets.zero,
      // **Pinned, but from inside the scroll view — see `_level`.** The shell's
      // `subheader` slot sits above the body, which put the selector above the
      // three overview sections it does not govern: pressing `30 days` changed
      // nothing in the 24dp directly under it. BR-197's requirement is that the
      // selector stays on screen while fifty decks scroll, not that it sits
      // under the app bar, and a `PinnedHeaderSliver` after the overview band
      // satisfies it without the misread.
      body: _hasNothingToMeasure
          ? _emptyLevelWithHeader(context)
          : _level(context),
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
        // `xl` below the band, the same section break the panel uses: the
        // overview and the level are two sections, not two rows of one.
        if (header case final Widget band)
          SliverToBoxAdapter(child: ProgressLevelHeaderWidget(child: band)),
        // Sticks once the overview has scrolled past, and travels with it until
        // then. `PinnedHeaderSliver` rather than `SliverPersistentHeader`
        // because the strip has no fixed height: it is 48 up to text scale 1.3
        // and 58 at 2.0, measured, so a delegate declaring an extent would clip
        // it for exactly the readers who need the larger type.
        PinnedHeaderSliver(
          // Opaque, because the deck rows now scroll *under* it rather than
          // beside it. `DecoratedBox` rather than `ColoredBox`: the visual
          // audit reads a decoration's colour off the render object and cannot
          // read a `ColoredBox`, so the cheaper widget would have cost an
          // allowance saying "trust me, it is surface".
          child: DecoratedBox(
            decoration: BoxDecoration(color: context.colors.surface),
            child: MxSubheaderBand(
              gutter: gutter,
              child: ProgressRangeSelectorWidget(
                range: range,
                onRangeChanged: onRangeChanged,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              // The range strip is directly above at every level and carries
              // its own bottom padding, so the panel adds none of its own —
              // this used to depend on whether the overview band was there,
              // back when the strip lived outside the scroll view.
              0,
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
            // depends on which window is selected (BR-197) and the window is a
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

  /// The empty level, with the header still above it when there is one.
  ///
  /// **The header must survive this branch.** It is the whole-library overview,
  /// and the library having no decks does not make streak, today and the last
  /// seven days untrue — it is a fact about the level, not about the week. The
  /// first version of the composition put the header only in `_level`, so a
  /// library with no decks silently dropped three sections that had data in
  /// them, and every screen test that expected them failed at once. That is the
  /// honest failure; the quiet one would have been a user seeing an empty state
  /// where their streak was.
  Widget _emptyLevelWithHeader(BuildContext context) {
    return ProgressHeaderedBody(header: header, body: _emptyLevel(context));
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
