import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/foundations/app_spacing.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_breadcrumb.dart';
import '../../../../shared/widgets/mx_fab.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_icon_button.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/models/deck_content_type_model.dart';
import '../../domain/models/deck_list_snapshot_model.dart';
import '../controllers/deck_list_controller.dart';
import '../controllers/deck_list_view_controller.dart';
import '../states/deck_list_view_state.dart';
import '../widgets/overlays/deck_actions_widget.dart';
import '../widgets/overlays/library_menu_widget.dart';
import '../widgets/overlays/deck_confirm_widget.dart';
import '../widgets/overlays/deck_create_child_widget.dart';
import '../widgets/sections/deck_level_error_widget.dart';
import '../widgets/sections/deck_list_sliver_widget.dart';
import '../widgets/sections/deck_summary_section_widget.dart';
import '../widgets/sections/deck_list_toolbar_widget.dart';
import '../widgets/sections/deck_subheader_widget.dart';
import '../widgets/sections/deck_card_handoff_widget.dart';
import '../widgets/support/deck_undo_widget.dart';

/// The toolbar's two commands, bound to a `ref`.
///
/// Free functions rather than closures written inline in `build()`. `ref.read` is
/// the right call — choosing a filter is a command, and a `watch` inside a
/// callback would subscribe the widget to a value it is about to set — but
/// written inline it sits lexically inside `build`, where neither a reader nor
/// `memox.state_management.no_ref_read_in_build` can tell a deliberate command
/// from a missed subscription. Hoisting it makes the distinction structural.
ValueChanged<DeckListFilter> _selectFilter(WidgetRef ref) =>
    (DeckListFilter value) =>
        ref.read(deckListFilterChoiceProvider.notifier).select(value);

ValueChanged<DeckListSort> _selectSort(WidgetRef ref) =>
    (DeckListSort value) =>
        ref.read(deckListSortChoiceProvider.notifier).select(value);

/// The bar actions a level can draw before its data arrives.
///
/// **One row: search, the primary create, one overflow** (owner mockup,
/// 2026-08-20). The bar leads with the two actions a library is used for —
/// finding and adding — and everything rarer lives behind one kebab, so the row
/// never grows past three targets.
///
/// **Hoisted out of the loaded branch so all three read states carry the same
/// row.** The shell is rebuilt inside each async branch — see
/// [DeckListScreen.build] for why the frame cannot simply wrap them — and the
/// two frames before the data used to pass no `actions` at all. At the root
/// that is not cosmetic: this overflow is the only door to Trash (AD-22 keeps
/// the entry root-only) and to the tag catalogue, so every failed read closed
/// both, on the one screen where a failed read is most likely to be what the
/// user needs to get out of.
///
/// Neither action needs the snapshot, which is what makes them safe to build
/// without it: search navigates, and the due-only toggle reads its state from
/// [deckListFilterChoiceProvider]. The deck's own menu does need the parent, so
/// it stays in [_DeckLevel] where the parent is known.
List<Widget> _chromeActions(
  BuildContext context,
  WidgetRef ref,
  DeckListFilter filter, {
  required bool isRootLevel,
}) {
  return <Widget>[
    MxIconButton(
      icon: Icons.search,
      semanticLabel: context.l10n.librarySearchOpenLabel,
      tooltip: context.l10n.librarySearchOpenLabel,
      // **`push`, not `go`.** Search is a *sibling* of the deck-detail
      // route under `/`, so `go` would rebuild the match list and throw
      // away every level below the root (wireframe S2/W4). Pushed, it
      // stays on the branch navigator and the bottom bar holds.
      onPressed: () => context.pushNamed(RouteNames.librarySearch),
    ),
    // The root's overflow: tag catalog (UC-18), Trash (AD-22 — the entry
    // stays root-only and unbadged; wireframe T2's "always on the bar"
    // is amended to "always in the bar's menu", recorded in the parity
    // checklist), and the due-only view toggle that left the toolbar.
    if (isRootLevel)
      MxIconButton(
        icon: Icons.more_vert,
        semanticLabel: context.l10n.libraryActionsTitle,
        tooltip: context.l10n.libraryActionsTitle,
        onPressed: () => showLibraryMenu(
          context,
          isDueFilterActive: filter == DeckListFilter.due,
          onToggleDueFilter: () => _selectFilter(ref)(
            filter == DeckListFilter.due
                ? DeckListFilter.all
                : DeckListFilter.due,
          ),
        ),
      ),
  ];
}

/// One level of the deck tree (UC-06, UC-08).
///
/// **The same screen at every depth**, which is the point. [parentDeckId] null is
/// the app's home — every root deck; any other id is what is inside that deck.
/// Opening a deck does not change what the user is looking at, it changes which
/// level of the same tree, so it does not get a different screen.
///
/// It was two: `RootDeckListScreen` with counts, a filter and a sort, and
/// `DeckDetailScreen` with a plainer list of names. Neither difference was a
/// design decision — the second screen showed less because the read underneath it
/// returned less. Both are now one read, one card and one layout, and the
/// sameness is structural rather than something two files have to maintain.
///
/// What legitimately differs by level is small and all of it comes from the
/// snapshot: the title, whether the app bar carries an action menu for the deck
/// being looked inside, and which create action the floating button starts.
class DeckListScreen extends StatelessWidget {
  const DeckListScreen({this.parentDeckId, super.key});

  /// Null at the root of the tree.
  final String? parentDeckId;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final isRootLevel = parentDeckId == null;
        // Watched here rather than only in the data branch: the overflow shows
        // whether the due-only view is on, so the frames before the data have
        // to rebuild when it changes too.
        final filter = ref.watch(deckListFilterChoiceProvider);
        // The row for the two frames that have no snapshot to build one from.
        // The loaded level calls the same function and appends the deck's own
        // menu, which is the only part of the row that needs the deck.
        final actions = _chromeActions(
          context,
          ref,
          filter,
          isRootLevel: isRootLevel,
        );

        return MxAsyncView<DeckListSnapshot>(
          value: ref.watch(deckListProvider(parentDeckId)),
          loadingLabel: context.l10n.decksLoadingLabel,
          // The shell is inside each branch rather than around them, because the
          // title is only knowable in some of them — see [_titleBeforeData].
          // What does *not* vary by branch is passed to all three: the actions
          // above and the subline's reserved height below.
          loadingFrame: (loading) => MxContentShell(
            title: _titleBeforeData(context),
            actions: actions,
            titleSubline: _sublineBeforeData(),
            body: loading,
          ),
          data: (snapshot) => _DeckLevel(
            snapshot: snapshot,
            filter: filter,
            sort: ref.watch(deckListSortChoiceProvider),
            onFilterChanged: _selectFilter(ref),
            onSortChanged: _selectSort(ref),
          ),
          error: (error, stackTrace) => DeckLevelErrorWidget(
            error: error,
            title: _titleBeforeData(context),
            actions: actions,
            isRootLevel: isRootLevel,
            // `invalidate`, not `refresh`: the retry wants a read from scratch
            // and nothing here needs the new value as a return. `refresh` would
            // also read it immediately, which the rebuild does anyway.
            onRetry: () => ref.invalidate(deckListProvider(parentDeckId)),
          ),
        );
      },
    );
  }

  /// The app-bar title for a level whose data has not arrived, or `null` when
  /// there is honestly none yet.
  ///
  /// The root level's title is a constant, so keeping it through loading and
  /// through a failed read means the screen does not appear to be replaced every
  /// time the data changes. A deck's title is its name, which is *in* the data —
  /// so a level inside a deck shows no bar until it has one, rather than a blank
  /// one or, worse, the previous deck's name.
  String? _titleBeforeData(BuildContext context) =>
      parentDeckId == null ? context.l10n.decksTitle : null;

  /// The height the loaded bar's second line will take, reserved before the
  /// data arrives — at the root only.
  ///
  /// **The bar grew 56 -> 84dp the instant the snapshot landed**, and every
  /// body pixel moved down with it: 28dp at text scale 1.0, 37.5dp at 2.0.
  /// [MxContentShell] sizes the row to the block it holds, and only the loaded
  /// shell passed a subline, so the arithmetic at `_toolbarHeight` applied to
  /// one branch out of three. An empty line of the same height makes the three
  /// states one bar.
  ///
  /// **Root only, deliberately.** A subline tells the shell the title owns the
  /// way back — `automaticallyImplyLeading` is false beside one — which is true
  /// of a loaded level, where the breadcrumb draws its own chevron, and false
  /// of a level whose breadcrumb has not arrived: reserving the slot inside a
  /// deck would buy an even bar and pay for it with a titleless, back-less one.
  /// So inside a deck the bar stays 56dp in the frames before the data, and
  /// steps once when the name and the path arrive together.
  Widget? _sublineBeforeData() => parentDeckId == null
      ? const SizedBox(height: MxBreadcrumb.compactLineHeight)
      : null;
}

/// A level that loaded: its chrome, and whatever the current view of it shows.
class _DeckLevel extends ConsumerWidget {
  const _DeckLevel({
    required this.snapshot,
    required this.filter,
    required this.sort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final DeckListSnapshot snapshot;
  final DeckListFilter filter;
  final DeckListSort sort;
  final ValueChanged<DeckListFilter> onFilterChanged;
  final ValueChanged<DeckListSort> onSortChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parent = snapshot.parent;

    return MxContentShell(
      // The level names itself: the app at the root, the deck below it.
      title: parent?.name ?? context.l10n.decksTitle,
      // The row every read state of this level draws, built once in
      // [_chromeActions] so a slow or failed read cannot quietly draw a
      // different one. Only the deck's own menu is added here, because only
      // here is there a deck to add it for.
      actions: <Widget>[
        ..._chromeActions(context, ref, filter, isRootLevel: parent == null),
        // A deck's own menu, which also carries the level's view toggle now.
        if (parent != null)
          MxIconButton(
            icon: Icons.more_vert,
            semanticLabel: context.l10n.deckActionsSemanticLabel,
            onPressed: () => showDeckActions(
              context,
              deck: parent,
              isDueFilterActive: filter == DeckListFilter.due,
              onToggleDueFilter: () => onFilterChanged(
                filter == DeckListFilter.due
                    ? DeckListFilter.all
                    : DeckListFilter.due,
              ),
              // The deck being viewed is gone, so staying here would show a
              // not-found state the user did not ask for. Going **up one
              // level** — not to the root — is where the deck was, and its
              // siblings are what the user was browsing.
              onDeleted: (batchId) {
                leaveDeletedDeck(context, parent);
                showDeckMovedToTrash(context, ref, batchId: batchId);
              },
            ),
          ),
      ],
      // The shell's own padding is dropped: the body is one scroll view and
      // owns its gutters.
      padding: EdgeInsets.zero,
      // **Create floats again, reversing M4.10ag** (owner review,
      // 2026-08-20). It was moved onto the bar because a floating button
      // covers whatever row sits under it — on a deck card, its overflow
      // menu. What made it a bar action then was the fill it needed to read
      // as primary, and a filled square between two outlined glyphs
      // outweighed the title. As a real FAB the weight is where it belongs,
      // and the row it used to cover is answered by the list's own bottom
      // inset rather than by moving the button.
      //
      // Absent where the action is: a `card` deck holds no sub-decks (BR-63).
      floatingActionButton: _mayCreate(parent)
          ? MxFab(
              icon: Icons.add,
              label: _createLabel(context, parent),
              onPressed: () => _startCreate(context, parent),
            )
          : null,
      // **The path is the bar's second line, not a band under it.** It was
      // already pinned in the subheader slot; what that slot could not do is
      // make it read as part of the header — the bar's bottom slack, the
      // band's padding and the strip's own touch floor added up to about 60px
      // of nothing between the title and the path, so the two looked like
      // separate components (owner review, 2026-08-20).
      //
      // Above every body state, including the empty ones — "where am I" is most
      // worth answering on a level with nothing in it to recognise.
      titleSubline: DeckSubheaderWidget(snapshot: snapshot),
      body: _body(context, parent),
    );
  }

  Widget _body(BuildContext context, DeckEntity? parent) {
    // A `card` deck hands off to its card screen (AD-13, BR-63).
    if (parent != null && parent.contentType == DeckContentType.card) {
      return DeckCardHandoffWidget(deckId: parent.id);
    }

    // Nothing here at all. The toolbar is not built for this state on purpose: a
    // filter and a sort over nothing are two controls that visibly do nothing,
    // which is exactly the dead control this design refused to copy.
    if (snapshot.decks.isEmpty) return _emptyLevel(context, parent);

    final visible = applyDeckListView(
      snapshot.decks,
      filter: filter,
      sort: sort,
    );

    // **One scroll view, not a pinned block above a scrolling one.** The summary
    // panel and the toolbar used to sit outside the list, so their height came
    // out of the *screen* rather than the scroll — and stopped fitting the
    // moment the breadcrumb strip joined the chrome above them. They scroll now:
    // nothing here has a height budget, so growing the chrome cannot overflow.
    return CustomScrollView(
      slivers: <Widget>[
        // What this level amounts to, above the list of what is in it — or the
        // line that brings it back once dismissed.
        SliverToBoxAdapter(child: DeckSummarySectionWidget(snapshot: snapshot)),
        // **The same policy the level-empty case above already follows.** A
        // filter that matches nothing leaves a heading counting to zero — "SUB-
        // DECKS · 0" — over a sort control acting on no rows, which is the dead
        // control this design refused to copy; the exemption was never decided,
        // it was where the early return happened to stop. The way back out of
        // the filter is on the empty face itself (`decksShowAllAction`), so
        // dropping the toolbar takes nothing with it.
        if (visible.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              // **Zero, because the tie is already 19px of ink-to-card and the
              // token was buying nothing** (owner decision, 2026-08-25). The gap
              // this carried for four passes answered "a section break no larger
              // than the 16 between two cards makes the heading read as the
              // list's first row" — true of a heading floating between two
              // groups, and this one belongs to the list. The ruler then drew the
              // cost of that reading, and measuring the *ink* rather than the
              // boxes showed why the token could go entirely:
              //
              //     above the cap  32.09 = token 12 + row-centring 16 + 4.09
              //     below the cap  27.19 = descent 3.19 + row-centring 16 + 8
              //
              // Both 16s are `MxTextButton`'s 48px touch target, which sets the
              // row's whole height and splits evenly around a 16px label box.
              // They are not padding and there is nothing to delete. So the
              // label's real distance to the first card never drops below
              // `3.19 + 16 = 19.19` no matter what goes here — the `sm` was
              // stacked on top of a gap that already read as generous, and
              // dropping it takes the ratio above:below from 1.18, where the
              // label is equidistant and groups with neither, to 1.67.
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                0,
              ),
              child: DeckListToolbarWidget(
                isRootLevel: parent == null,
                filter: filter,
                sort: sort,
                visibleCount: visible.length,
                onFilterChanged: onFilterChanged,
                onSortChanged: onSortChanged,
              ),
            ),
          ),
        DeckListSliverWidget(
          summaries: visible,
          manualSummaries: snapshot.decks,
          isManualSort: sort == DeckListSort.manual,
          onClearFilter: () => onFilterChanged(DeckListFilter.all),
        ),
      ],
    );
  }

  /// The empty state, which differs by level and by content type because the next
  /// step does.
  ///
  /// An `unset` deck can still become either kind, so BR-61 requires both choices
  /// to be visible — the card one disabled, with the reason, rather than hidden.
  /// Hiding it would teach the user this deck can only hold decks, which is not
  /// true until they add one.
  Widget _emptyLevel(BuildContext context, DeckEntity? parent) {
    if (parent == null) {
      return MxEmptyState(
        // Not the default check-mark: that icon says "you have finished
        // everything", which is the opposite of what an account with no decks
        // means.
        icon: Icons.folder_outlined,
        title: context.l10n.decksEmptyTitle,
        message: context.l10n.decksEmptyMessage,
        // **The primary is the action the floating button already starts.**
        // Three call-to-actions are on this screen — the FAB, and this pair —
        // and the loudest of them, a filled brand-coloured FAB, says "New
        // deck"; ranking Starter library above it made the screen state a
        // preference and then contradict it, while naming the same create
        // action twice in two weights. The card list's empty state pairs its
        // chrome affordance with its primary and puts the alternative path in
        // the secondary slot (`card_list_screen.dart`, `_Empty`); this is the
        // same pairing, which that file's comment already claims the deck list
        // uses.
        //
        // Starter library keeps its place as the second path — production
        // seeds nothing, so a catalogue of ready-made decks is a real answer on
        // a first run — but it is one tap away rather than the loudest thing on
        // the screen.
        actionLabel: context.l10n.deckCreateRootAction,
        onAction: () => showCreateRootDeckForm(context),
        secondaryActionLabel: context.l10n.deckStarterLibraryAction,
        onSecondaryAction: () => context.goNamed(RouteNames.starterLibrary),
      );
    }

    final isUnset = parent.contentType == DeckContentType.unset;

    // **An empty `unset` deck offers both kinds (BR-61).** It used to offer only
    // a sub-deck beside a notice saying cards were unavailable — which left the
    // deck unable to ever hold one, because the card screen opens only after
    // `content_type` is already `card` and only a card can set it (BR-62).
    return MxEmptyState(
      icon: Icons.folder_outlined,
      title: isUnset
          ? context.l10n.deckDetailEmptyUnsetTitle
          : context.l10n.deckDetailEmptyDeckTitle,
      message: isUnset
          ? context.l10n.deckDetailEmptyUnsetMessage
          : context.l10n.deckDetailEmptyDeckMessage,
      // One action, named once. The floating button starts the same
      // `showCreateChildForm` at both content types and calls it "New
      // sub-deck" either way, so a second name for it here read as a second
      // action. The unset fork is still there — the message above says a card
      // or a sub-deck, and the form asks which (BR-61) — it is just no longer
      // announced by two buttons that disagree about what they do.
      actionLabel: context.l10n.deckCreateSubDeckAction,
      onAction: () => showCreateChildForm(context, parent: parent),
    );
  }

  /// Creating is allowed at the root always, and inside a deck unless it is fixed
  /// to cards (BR-59, BR-64, BR-66).
  ///
  /// Depth is not checked here: the repository refuses a create past level 10
  /// before writing anything (BR-55), and a UI that also guessed at depth would
  /// need the ancestry this screen does not load.
  static bool _mayCreate(DeckEntity? parent) =>
      parent == null || parent.contentType != DeckContentType.card;

  static String _createLabel(BuildContext context, DeckEntity? parent) =>
      parent == null
      ? context.l10n.deckCreateRootAction
      : context.l10n.deckCreateSubDeckAction;

  /// Returns the sheet's future rather than dropping it, so a caller that wants
  /// to wait for the form to close can. Nothing here awaits it: the list is
  /// driven by the repository's stream, so the new deck arrives on its own.
  static Future<void> _startCreate(BuildContext context, DeckEntity? parent) {
    if (parent == null) return showCreateRootDeckForm(context);

    // An `unset` deck is asked which kind of child (BR-61); a settled one goes
    // straight to the matching form (BR-66).
    return showCreateChildForm(context, parent: parent);
  }
}
